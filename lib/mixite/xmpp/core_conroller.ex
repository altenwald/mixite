defmodule Mixite.Xmpp.CoreController do
  use Exampple.Component

  import Exampple.Xml.Xmlel, only: [sigil_x: 2]
  import Mixite.Xmpp.ErrorController, only: [send_not_found: 1, send_forbidden: 1]

  alias Exampple.Router.Conn
  alias Exampple.Xml.Xmlel
  alias Exampple.Xmpp.Jid
  alias Mixite.Groupchat

  def join(%Conn{to_jid: %Jid{node: channel}} = conn, [query]) when channel != "" do
    if groupchat = Groupchat.get(channel) do
      user_jid = Jid.to_bare(conn.from_jid)
      nick =
        case query["nick"] do
          [%Xmlel{children: [nick]}] -> nick
          _ -> nil
        end

      if {id, nodes} = Groupchat.join(groupchat, user_jid, nick) do
        payload =
          %Xmlel{
            name: "join",
            attrs: %{"xmlns" => "urn:xmpp:mix:core:1", "id" => id},
            children:
              for(node <- nodes, do: subscribe(node)) ++
              [%Xmlel{name: "nick", children: [nick]}]
          }
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

  defp subscribe(node) do
    ~x[<subscribe node='urn:xmpp:mix:nodes:#{node}'/>]
  end
end
