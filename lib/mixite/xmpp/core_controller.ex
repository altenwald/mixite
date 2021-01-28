defmodule Mixite.Xmpp.CoreController do
  use Exampple.Component

  require Logger

  import Mixite.Xmpp.ErrorController,
    only: [
      send_not_found: 1,
      send_forbidden: 1,
      send_conflict: 1,
      send_feature_not_implemented: 3,
      send_internal_error: 1
    ]

  alias Exampple.Router.Conn
  alias Exampple.Xml.Xmlel
  alias Exampple.Xmpp.Jid
  alias Mixite.{Channel, EventManager}

  @xmlns "urn:xmpp:mix:core:1"
  @prefix_ns "urn:xmpp:mix:nodes:"

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
            attrs: %{"xmlns" => @xmlns, "channel" => channel.id}
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
        _ -> send_feature_not_implemented(conn, "en", "child unknown: #{to_string(query)}")
      end
    else
      send_not_found(conn)
    end
  end

  defp set_nick(conn, [%Xmlel{children: [nick]}], channel) do
    user_jid = Jid.to_bare(conn.from_jid)

    if Channel.is_participant?(channel, user_jid) do
      case Channel.set_nick(channel, user_jid, nick) do
        :ok ->
          conn
          |> iq_resp()
          |> send()

        {:error, :conflict} ->
          Logger.error("user #{user_jid} cannot change nick to #{nick} because conflict")
          send_conflict(conn)

        {:error, error} ->
          Logger.error("user #{user_jid} cannot change nick to #{nick} because #{inspect(error)}")
          send_internal_error(conn)
      end
    else
      send_forbidden(conn)
    end
  end

  defp leave(conn, _query, channel) do
    user_jid = Jid.to_bare(conn.from_jid)

    if Channel.is_participant?(channel, user_jid) do
      to_jid = to_string(conn.to_jid)

      case Channel.leave(channel, user_jid) do
        :ok ->
          {participant, channel} = Channel.split(channel, user_jid)
          EventManager.notify({:leave, participant.id, to_jid, user_jid, channel})

          conn
          |> iq_resp()
          |> send()

        {:error, :notfound} ->
          Logger.error("user #{user_jid} tried leave #{to_jid} not found")
          send_not_found(conn)

        {:error, _} = error ->
          Logger.error("leave feature error: #{inspect(error)}")
          send_feature_not_implemented(conn, "en", "leave is not supported")
      end
    else
      send_forbidden(conn)
    end
  end

  defp update(conn, query, channel) do
    user_jid = Jid.to_bare(conn.from_jid)

    if Channel.is_participant?(channel, user_jid) do
      nodes_add =
        for %Xmlel{attrs: %{"node" => @prefix_ns <> node}} <- query["subscribe"], do: node

      nodes_rem =
        for %Xmlel{attrs: %{"node" => @prefix_ns <> node}} <- query["unsubscribe"], do: node

      case Channel.update(channel, user_jid, nodes_add, nodes_rem) do
        {:ok, {_channel, add_nodes, rem_nodes}} ->
          from_jid = Jid.to_bare(conn.from_jid)
          add_nodes = for node <- add_nodes, do: subscribe(node)
          rem_nodes = for node <- rem_nodes, do: unsubscribe(node)

          payload = %Xmlel{
            name: "update-subscription",
            attrs: %{"xmlns" => @xmlns, "jid" => from_jid},
            children: add_nodes ++ rem_nodes
          }

          conn
          |> iq_resp([payload])
          |> send()

        {:error, :not_implemented} ->
          Logger.error("update feature not implemented")
          send_feature_not_implemented(conn, "en", "update is not supported")

        {:error, _} = error ->
          Logger.error("update failed: #{inspect(error)}")
          send_internal_error(conn)
      end
    else
      send_forbidden(conn)
    end
  end

  defp join(conn, query, channel) do
    user_jid = Jid.to_bare(conn.from_jid)

    nick =
      case query["nick"] do
        [%Xmlel{children: [nick]}] -> nick
        _ -> nil
      end

    nodes_in = for %Xmlel{attrs: %{"node" => @prefix_ns <> node}} <- query["subscribe"], do: node

    case Channel.join(channel, user_jid, nick, nodes_in) do
      {:error, :not_implemented} ->
        Logger.error("join feature not implemented")
        send_feature_not_implemented(conn, "en", "join not implemented")

      {:error, :forbidden} ->
        Logger.error("user #{user_jid} was not granted to join #{channel}")
        send_feature_not_implemented(conn, "en", "join not implemented")

      {:error, _} = error ->
        Logger.error("join failed: #{inspect(error)}")
        send_internal_error(conn)

      {:ok, {participant, nodes}} ->
        payload = %Xmlel{
          name: "join",
          attrs: %{"xmlns" => @xmlns, "id" => participant.id},
          children:
            for(node <- nodes, do: subscribe(node)) ++
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
    full_node_name = "#{@prefix_ns}#{node}"
    %Xmlel{name: "unsubscribe", attrs: %{"node" => full_node_name}}
  end

  defp subscribe(node) do
    full_node_name = "#{@prefix_ns}#{node}"
    %Xmlel{name: "subscribe", attrs: %{"node" => full_node_name}}
  end
end
