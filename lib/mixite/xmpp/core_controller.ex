defmodule Mixite.Xmpp.CoreController do
  use Exampple.Component

  import Mixite.Xmpp.ErrorController, only: [send_not_found: 1, send_forbidden: 1]

  alias Exampple.Router.Conn
  alias Exampple.Xml.Xmlel
  alias Exampple.Xmpp.Jid
  alias Mixite.{EventManager, Groupchat}

  def core(conn, [%Xmlel{name: "join"} | _] = query) do
    join(conn, query)
  end

  def core(conn, [%Xmlel{name: "update-subscription"} | _] = query) do
    update(conn, query)
  end

  def update(%Conn{to_jid: %Jid{node: channel}} = conn, [query]) when channel != "" do
    user_id = to_string(Jid.to_bare(conn.from_jid))
    if groupchat = Groupchat.get(channel) do
      if Enum.any?(groupchat.participants, fn {_, _, jid} -> jid == user_id end) do
        nodes_add =
          for %Xmlel{attrs: %{"node" => "urn:xmpp:mix:nodes:" <> node}} <- query["subscribe"], do: node

        nodes_rem =
          for %Xmlel{attrs: %{"node" => "urn:xmpp:mix:nodes:" <> node}} <- query["unsubscribe"], do: node

        case Groupchat.update(groupchat, conn.from_jid.node, nodes_add, nodes_rem) do
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
    else
      send_not_found(conn)
    end
  end

  def join(%Conn{to_jid: %Jid{node: channel}} = conn, [query]) when channel != "" do
    if groupchat = Groupchat.get(channel) do
      user_jid = Jid.to_bare(conn.from_jid)
      nick =
        case query["nick"] do
          [%Xmlel{children: [nick]}] -> nick
          _ -> nil
        end

      nodes_in =
        for %Xmlel{attrs: %{"node" => "urn:xmpp:mix:nodes:" <> node}} <- query["subscribe"], do: node

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
    else
      send_not_found(conn)
    end
  end

  defp unsubscribe(node) do
    full_node_name = "urn:xmpp:mix:nodes:#{node}"
    %Xmlel{name: "unsubscribe", attrs: %{"node" => full_node_name}}
  end

  defp subscribe(node) do
    full_node_name = "urn:xmpp:mix:nodes:#{node}"
    %Xmlel{name: "subscribe", attrs: %{"node" => full_node_name}}
  end
end
