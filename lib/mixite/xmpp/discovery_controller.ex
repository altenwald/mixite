defmodule Mixite.Xmpp.DiscoveryController do
  use Exampple.Component
  use Mixite.Namespaces

  import Exampple.Xml.Xmlel, only: [sigil_x: 2]
  import Mixite.Xmpp.ErrorController, only: [send_not_found: 1, send_forbidden: 1]

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

  def items(%Conn{to_jid: %Jid{node: ""}} = conn, _query) do
    from_jid = Jid.to_bare(conn.from_jid)
    channels = Channel.list_by_jid(from_jid)

    items =
      for channel <- channels do
        "<item jid='#{channel.id}@#{conn.domain}'/>"
      end

    payload = ~x[
      <query xmlns='http://jabber.org/protocol/disco#items'>
        #{Enum.join(items)}
      </query>
    ]

    conn
    |> iq_resp([payload])
    |> send()
  end

  def items(%Conn{to_jid: %Jid{node: channel_id}} = conn, _query) do
    from_jid = Jid.to_bare(conn.from_jid)

    with channel = %Channel{} <- Channel.get(channel_id),
         true <- Channel.can_view?(channel, @ns_info, from_jid) do
      items =
        ["messages", "config" | channel.nodes]
        |> Enum.reduce([], &(&2 ++ node_to_ns(&1)))
        |> Enum.map(&"<item jid='#{channel.id}@#{conn.domain}' node='#{&1}'/>")

      payload = ~x[
        <query xmlns='http://jabber.org/protocol/disco#items' node='mix'>
          #{Enum.join(items)}
        </query>
      ]

      conn
      |> iq_resp([payload])
      |> send()
    else
      nil -> send_not_found(conn)
      false -> send_forbidden(conn)
    end
  end
end
