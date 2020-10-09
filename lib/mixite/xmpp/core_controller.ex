defmodule Mixite.Xmpp.CoreController do
  use Exampple.Component

  require Logger

  import Mixite.Xmpp.ErrorController, only: [
    send_not_found: 1,
    send_forbidden: 1,
    send_feature_not_implemented: 2,
    send_internal_error: 1
  ]

  alias Exampple.Router.Conn
  alias Exampple.Xml.Xmlel
  alias Exampple.Xmpp.Jid
  alias Mixite.{EventManager, Groupchat}

  @prefix_ns "urn:xmpp:mix:nodes:"

  def core(%Conn{to_jid: %Jid{node: ""}} = conn, _query) do
    send_feature_not_implemented(conn, "namespace #{conn.xmlns} requires a channel")
  end

  def core(conn, query) when length(query) != 1 do
    send_feature_not_implemented(conn, "iq must have only and at least one child")
  end

  def core(%Conn{to_jid: %Jid{node: channel}} = conn, [query]) do
    if groupchat = Groupchat.get(channel) do
      case query do
        %Xmlel{name: "join"} -> join(conn, query, groupchat)
        %Xmlel{name: "update-subscription"} -> update(conn, query, groupchat)
        %Xmlel{name: "leave"} -> leave(conn, query, groupchat)
        %Xmlel{name: "setnick"} -> set_nick(conn, query["nick"], groupchat)
      end
    else
      send_not_found(conn)
    end
  end

  defp set_nick(conn, [%Xmlel{children: [nick]}], groupchat) do
    user_jid = to_string(Jid.to_bare(conn.from_jid))
    if Groupchat.is_participant?(groupchat, user_jid) do
      to_jid = to_string(conn.to_jid)
      if Groupchat.set_nick(groupchat, user_jid, nick) do
        conn
        |> iq_resp()
        |> send()
      else
        Logger.error("user #{user_jid} tried leave #{to_jid} unsuccessfully")
        send_internal_error(conn)
      end
    else
      send_forbidden(conn)
    end
  end

  defp leave(conn, _query, groupchat) do
    user_jid = to_string(Jid.to_bare(conn.from_jid))
    if Groupchat.is_participant?(groupchat, user_jid) do
      to_jid = to_string(conn.to_jid)
      if Groupchat.leave(groupchat, user_jid) do
        {{id, _, _}, groupchat} = Groupchat.split(groupchat, user_jid)
        EventManager.notify({:leave, id, to_jid, user_jid, groupchat})

        conn
        |> iq_resp()
        |> send()
      else
        Logger.error("user #{user_jid} tried leave #{to_jid} unsuccessfully")
        send_internal_error(conn)
      end
    else
      send_forbidden(conn)
    end
  end

  defp update(conn, query, groupchat) do
    user_jid = to_string(Jid.to_bare(conn.from_jid))
    if Groupchat.is_participant?(groupchat, user_jid) do
      nodes_add =
        for %Xmlel{attrs: %{"node" => @prefix_ns <> node}} <- query["subscribe"], do: node

      nodes_rem =
        for %Xmlel{attrs: %{"node" => @prefix_ns <> node}} <- query["unsubscribe"], do: node

      case Groupchat.update(groupchat, user_jid, nodes_add, nodes_rem) do
        {:ok, {add_nodes, rem_nodes}} ->
          from_jid = to_string(Jid.to_bare(conn.from_jid))
          add_nodes = for node <- add_nodes, do: subscribe(node)
          rem_nodes = for node <- rem_nodes, do: unsubscribe(node)
          payload =
            %Xmlel{
              name: "update-subscription",
              attrs: %{"xmlns" => "urn:xmpp:mix:core:1", "jid" => from_jid},
              children: add_nodes ++ rem_nodes
            }

          conn
          |> iq_resp([payload])
          |> send()
        {:error, _} = error ->
          error
      end
    else
      send_forbidden(conn)
    end
  end

  defp join(conn, query, groupchat) do
    user_jid = Jid.to_bare(conn.from_jid)
    nick =
      case query["nick"] do
        [%Xmlel{children: [nick]}] -> nick
        _ -> nil
      end

    nodes_in =
      for %Xmlel{attrs: %{"node" => @prefix_ns <> node}} <- query["subscribe"], do: node

    if {id, nodes} = Groupchat.join(groupchat, user_jid, nick, nodes_in) do
      payload =
        %Xmlel{
          name: "join",
          attrs: %{"xmlns" => "urn:xmpp:mix:core:1", "id" => id},
          children:
            for(node <- nodes, do: subscribe(node)) ++
            [%Xmlel{name: "nick", children: [nick]}]
        }

      to_jid = to_string(conn.to_jid)
      EventManager.notify({:join, id, to_jid, user_jid, nick, groupchat})

      conn
      |> iq_resp([payload])
      |> send()
    else
      send_forbidden(conn)
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
