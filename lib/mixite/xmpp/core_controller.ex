defmodule Mixite.Xmpp.CoreController do
  use Exampple.Component
  use Mixite.Namespaces

  require Logger

  import Mixite.Xmpp.ErrorController,
    only: [
      send_not_found: 1,
      send_forbidden: 1,
      send_conflict: 3,
      send_feature_not_implemented: 3,
      send_internal_error: 1
    ]

  alias Exampple.Router.Conn
  alias Exampple.Xml.Xmlel
  alias Exampple.Xmpp.Jid
  alias Mixite.{Channel, EventManager}

  if Application.get_env(:mixite, :create_channel, true) do
    def core(%Conn{to_jid: %Jid{node: ""}} = conn, [%Xmlel{name: "create"} = query]) do
      user_jid = Jid.to_bare(conn.from_jid)
      # if a name is provided (7.3.2) or not (ad-hoc 7.3.3):
      channel_id = query.attrs["channel"] || Channel.gen_uuid()

      case Channel.create(channel_id, user_jid) do
        {:ok, channel} ->
          Logger.info("created channel #{channel.id}")

          payload = %Xmlel{
            name: "create",
            attrs: %{"xmlns" => @ns_core, "channel" => channel.id}
          }

          conn
          |> iq_resp([payload])
          |> send()

        {:error, error} ->
          Logger.error("creating #{inspect(error)}")
          send_internal_error(conn)
      end
    end
  end

  if Application.get_env(:mixite, :destroy_channel, true) do
    def core(%Conn{to_jid: %Jid{node: ""}} = conn, [%Xmlel{name: "destroy"} = query]) do
      user_jid = Jid.to_bare(conn.from_jid)

      if channel = Channel.get(query.attrs["channel"]) do
        if Channel.is_owner?(channel, user_jid) and Channel.destroy(channel, user_jid) do
          conn
          |> iq_resp()
          |> send()
        else
          send_forbidden(conn)
        end
      else
        send_not_found(conn)
      end
    end
  end

  def core(%Conn{to_jid: %Jid{node: ""}} = conn, _query) do
    send_feature_not_implemented(conn, "en", "namespace #{conn.xmlns} requires a channel")
  end

  def core(conn, query) when length(query) != 1 do
    send_feature_not_implemented(conn, "en", "iq must have only and at least one child")
  end

  def core(%Conn{to_jid: %Jid{node: channel_id}} = conn, [query]) do
    if channel = Channel.get(channel_id) do
      case query do
        %Xmlel{name: "join"} -> join(conn, query, channel)
        %Xmlel{name: "update-subscription"} -> update(conn, query, channel)
        %Xmlel{name: "leave"} -> leave(conn, query, channel)
        %Xmlel{name: "setnick"} -> set_nick(conn, query["nick"], channel)
        %Xmlel{name: name} -> send_feature_not_implemented(conn, "en", "child unknown: #{name}")
      end
    else
      send_not_found(conn)
    end
  end

  # TODO 7.1.4 - system could choose a nick for the user if it's empty
  defp set_nick(conn, [%Xmlel{children: [nick]}], channel) do
    user_jid = Jid.to_bare(conn.from_jid)
    mix_jid = Jid.to_bare(conn.to_jid)
    participant = Enum.find(channel.participants, &(&1.jid == user_jid))

    case Channel.set_nick(channel, user_jid, nick) do
      :ok when nick != participant.nick ->
        conn
        |> iq_resp()
        |> send()

        {participant, channel} = Channel.split(channel, user_jid)
        EventManager.notify({:set_nick, nick, participant, mix_jid, user_jid, channel})

      :ok ->
        conn
        |> iq_resp()
        |> send()

      {:error, :forbidden} ->
        send_forbidden(conn)

      {:error, :conflict} ->
        Logger.error("user #{user_jid} cannot change nick to #{nick} because conflict")
        send_conflict(conn, "en", "nickname already assigned")

      {:error, error} ->
        Logger.error("user #{user_jid} cannot change nick to #{nick} because #{inspect(error)}")
        send_internal_error(conn)
    end
  end

  defp leave(conn, _query, channel) do
    user_jid = Jid.to_bare(conn.from_jid)
    mix_jid = Jid.to_bare(conn.to_jid)

    case Channel.leave(channel, user_jid) do
      :ok ->
        {participant, channel} = Channel.split(channel, user_jid)
        EventManager.notify({:leave, participant.id, mix_jid, user_jid, channel})

        conn
        |> iq_resp()
        |> send()

      {:error, :forbidden} ->
        send_forbidden(conn)

      {:error, _} = error ->
        Logger.error("leave feature error: #{inspect(error)}")
        send_feature_not_implemented(conn, "en", "leave is not supported")
    end
  end

  defp update(conn, query, channel) do
    user_jid = Jid.to_bare(conn.from_jid)
    valid_ns = valid_ns()

    nodes_add =
      for %Xmlel{attrs: %{"node" => ns_node}} <- query["subscribe"], ns_node in valid_ns do
        ns_to_node(ns_node)
      end

    nodes_rem =
      for %Xmlel{attrs: %{"node" => ns_node}} <- query["unsubscribe"], ns_node in valid_ns do
        ns_to_node(ns_node)
      end

    case Channel.update_subscription(channel, user_jid, nodes_add, nodes_rem) do
      {:ok, {_channel, add_nodes, rem_nodes}} ->
        from_jid = Jid.to_bare(conn.from_jid)
        add_nodes = Enum.reduce(add_nodes, [], & &2 ++ subscribe(&1))
        rem_nodes = Enum.reduce(rem_nodes, [], & &2 ++ unsubscribe(&1))

        payload = %Xmlel{
          name: "update-subscription",
          attrs: %{"xmlns" => @ns_core, "jid" => from_jid},
          children: add_nodes ++ rem_nodes
        }

        conn
        |> iq_resp([payload])
        |> send()

      {:error, :forbidden} ->
        send_forbidden(conn)

      {:error, :not_implemented} ->
        Logger.error("update feature not implemented")
        send_feature_not_implemented(conn, "en", "update is not supported")

      {:error, _} = error ->
        Logger.error("update failed: #{inspect(error)}")
        send_internal_error(conn)
    end
  end

  defp join(conn, query, channel) do
    user_jid = Jid.to_bare(conn.from_jid)
    valid_ns = valid_ns()

    nick =
      case query["nick"] do
        [%Xmlel{children: [nick]}] -> nick
        _ -> nil
      end

    nodes_in =
      for %Xmlel{attrs: %{"node" => ns_node}} <- query["subscribe"], ns_node in valid_ns do
        ns_to_node(ns_node)
      end

    case Channel.join(channel, user_jid, nick, nodes_in) do
      {:error, :not_implemented} ->
        Logger.error("join feature not implemented")
        send_feature_not_implemented(conn, "en", "join not implemented")

      {:error, :forbidden} ->
        Logger.error("user #{user_jid} was not granted to join #{channel}")
        send_forbidden(conn)

      {:error, _} = error ->
        Logger.error("join failed: #{inspect(error)}")
        send_internal_error(conn)

      {:ok, {participant, nodes}} ->
        payload = %Xmlel{
          name: "join",
          attrs: %{"xmlns" => @ns_core, "id" => participant.id},
          children:
            Enum.reduce(nodes, [], & &2 ++ subscribe(&1)) ++
              [%Xmlel{name: "nick", children: [nick]}]
        }

        to_jid = to_string(conn.to_jid)
        EventManager.notify({:join, participant.id, to_jid, user_jid, nick, channel})

        conn
        |> iq_resp([payload])
        |> send()
    end
  end

  defp unsubscribe(node) do
    for full_node_name <- node_to_ns(node) do
      %Xmlel{name: "unsubscribe", attrs: %{"node" => full_node_name}}
    end
  end

  defp subscribe(node) do
    for full_node_name <- node_to_ns(node) do
      %Xmlel{name: "subscribe", attrs: %{"node" => full_node_name}}
    end
  end
end
