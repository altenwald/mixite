defmodule Mixite.Xmpp.PubsubController do
  use Exampple.Component

  import Mixite.Xmpp.ErrorController,
    only: [
      send_not_found: 1,
      send_forbidden: 1,
      send_error: 2
    ]

  alias Exampple.Router.Conn
  alias Exampple.Xml.Xmlel
  alias Exampple.Xmpp.Jid
  alias Mixite.Channel

  def get(conn, [%Xmlel{children: [%Xmlel{attrs: %{"node" => node}}]}]) do
    channel_id = if conn.to_jid.node != "", do: conn.to_jid.node
    from_jid = Jid.to_bare(conn.from_jid)

    case Channel.process_node(channel_id, from_jid, node) do
      :ignore ->
        case process_node(conn, node) do
          nil ->
            send_not_found(conn)

          :forbidden ->
            send_forbidden(conn)

          {:error, error} ->
            send_error(conn, error)

          %Xmlel{} = item ->
            conn
            |> iq_resp([pubsub(node, [item])])
            |> send()

          [%Xmlel{} | _] = items ->
            conn
            |> iq_resp([pubsub(node, items)])
            |> send()
        end

      {:error, error} ->
        send_error(conn, error)

      %Xmlel{} = item ->
        conn
        |> iq_resp([pubsub(node, [item])])
        |> send()

      [%Xmlel{} | _] = items ->
        conn
        |> iq_resp([pubsub(node, items)])
        |> send()
    end
  end

  def process_node(%Conn{to_jid: %Jid{node: channel_id}} = conn, "urn:xmpp:mix:nodes:config")
      when channel_id != "" do
    from_jid = Jid.to_bare(conn.from_jid)

    with channel = %Channel{} <- Channel.get(channel_id),
         true <- Channel.can_view?(channel, from_jid) do
      Channel.render(channel, "urn:xmpp:mix:nodes:config")
    else
      nil -> nil
      false -> :forbidden
    end
  end

  def process_node(%Conn{to_jid: %Jid{node: channel_id}} = conn, "urn:xmpp:mix:nodes:info")
      when channel_id != "" do
    from_jid = Jid.to_bare(conn.from_jid)

    with channel = %Channel{} <- Channel.get(channel_id),
         true <- Channel.can_view?(channel, from_jid) do
      Channel.render(channel, "urn:xmpp:mix:nodes:info")
    else
      nil -> nil
      false -> :forbidden
    end
  end

  def process_node(
        %Conn{to_jid: %Jid{node: channel_id}} = conn,
        "urn:xmpp:mix:nodes:participants"
      )
      when channel_id != "" do
    from_jid = Jid.to_bare(conn.from_jid)

    with channel = %Channel{} <- Channel.get(channel_id),
         true <- Channel.can_view?(channel, from_jid) do
      Channel.render(channel, "urn:xmpp:mix:nodes:participants")
    else
      nil -> nil
      false -> :forbidden
    end
  end

  def process_node(_conn, nodes) do
    {:error, {"feature-not-implemented", "en", "#{nodes} not implemented"}}
  end

  defp pubsub(node, items) do
    %Xmlel{
      name: "pubsub",
      attrs: %{"xmlns" => "http://jabber.org/protocol/pubsub"},
      children: [
        %Xmlel{
          name: "items",
          attrs: %{"node" => node},
          children: items
        }
      ]
    }
  end
end
