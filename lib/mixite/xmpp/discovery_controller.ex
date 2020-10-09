defmodule Mixite.Xmpp.DiscoveryController do
  use Exampple.Component

  import Exampple.Xml.Xmlel, only: [sigil_x: 2]
  import Mixite.Xmpp.ErrorController, only: [send_not_found: 1]

  alias Exampple.Router.Conn
  alias Exampple.Xmpp.Jid
  alias Mixite.Channel

  def info(%Conn{to_jid: %Jid{node: channel_id}} = conn, _query) when channel_id != "" do
    if channel = Channel.get(channel_id) do
      payload = ~x[
        <query xmlns='http://jabber.org/protocol/disco#info'>
          <identity category='conference' type='mix' name='#{channel.name}'/>
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

  def items(%Conn{to_jid: %Jid{node: channel_id}} = conn, _query) when channel_id != "" do
    if channel = Channel.get(channel_id) do
      items =
        for node <- channel.nodes do
          node = "urn:xmpp:mix:nodes:#{node}"
          "<item jid='#{channel_id}@#{conn.domain}' node='#{node}'/>"
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
