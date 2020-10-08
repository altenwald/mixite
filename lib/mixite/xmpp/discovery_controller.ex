defmodule Mixite.Xmpp.DiscoveryController do
  use Exampple.Component

  import Exampple.Xml.Xmlel, only: [sigil_x: 2]
  import Mixite.Xmpp.ErrorController, only: [send_not_found: 1]

  alias Exampple.Router.Conn
  alias Exampple.Xmpp.Jid
  alias Mixite.Groupchat

  def info(%Conn{to_jid: %Jid{node: channel}} = conn, _query) when channel != "" do
    if groupchat = Groupchat.get(channel) do
      payload = ~x[
        <query xmlns='http://jabber.org/protocol/disco#info'>
          <identity category='conference' type='mix' name='#{groupchat.name}'/>
          <feature var='http://jabber.org/protocol/disco#info'/>
          <feature var='urn:xmpp:mix:core:1'/>
          <feature var='urn:xmpp:mam:2'/>
        </query>
      ]

      conn
      |> iq_resp([payload])
      |> send()
    else
      send_not_found(conn)
    end
  end

  def items(%Conn{to_jid: %Jid{node: channel}} = conn, _query) when channel != "" do
    if groupchat = Groupchat.get(channel) do
      items =
        for node <- groupchat.nodes do
          node = "urn:xmpp:mix:nodes:#{node}"
          "<item jid='#{channel}@#{conn.domain}' node='#{node}'/>"
        end
        |> Enum.join()

      payload = ~x[
        <query xmlns='http://jabber.org/protocol/disco#items' node='mix'>
          #{items}
        </query>
      ]

      conn
      |> iq_resp([payload])
      |> send()
    else
      send_not_found(conn)
    end
  end
end
