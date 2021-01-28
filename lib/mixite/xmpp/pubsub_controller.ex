defmodule Mixite.Xmpp.PubsubController do
  use Exampple.Component

  import Mixite.Xmpp.ErrorController, only: [
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

  defp field(name, type \\ nil, value)
  defp field(_name, _type, nil), do: []
  defp field(_name, _type, []), do: []

  defp field(name, type, value) do
    children =
      if is_list(value) do
        for v <- value, do: %Xmlel{name: "value", children: [v]}
      else
        [%Xmlel{name: "value", children: [value]}]
      end

    attrs =
      if type do
        %{"var" => name, "type" => type}
      else
        %{"var" => name}
      end

    [%Xmlel{name: "field", attrs: attrs, children: children}]
  end

  def process_node(%Conn{to_jid: %Jid{node: channel_id}} = conn, "urn:xmpp:mix:nodes:config")
      when channel_id != "" do
    from_jid = Jid.to_bare(conn.from_jid)

    with channel = %Channel{} <- Channel.get(channel_id),
         true <- Channel.can_view?(channel, from_jid) do
      %Xmlel{
        name: "item",
        attrs: %{"id" => to_string(channel.updated_at)},
        children: [
          %Xmlel{
            name: "x",
            attrs: %{"xmlns" => "jabber:x:data", "type" => "result"},
            children:
              field("FORM_TYPE", "hidden", "urn:xmpp:mix:core:1") ++
                field("Owner", channel.owners) ++
                field("Administrator", channel.administrators) ++
                Enum.map(Channel.config_params(channel), fn
                  {{key, type}, value} -> hd(field(key, type, value))
                  {key, value} -> hd(field(key, value))
                end)
          }
        ]
      }
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
      %Xmlel{
        name: "item",
        attrs: %{"id" => to_string(channel.updated_at)},
        children: [
          %Xmlel{
            name: "x",
            attrs: %{"xmlns" => "jabber:x:data", "type" => "result"},
            children:
              field("FORM_TYPE", "hidden", "urn:xmpp:mix:core:1") ++
                field("Name", channel.name) ++
                field("Description", channel.description) ++
                field("Contact", channel.contact)
          }
        ]
      }
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
      for participant <- channel.participants do
        %Xmlel{
          name: "item",
          attrs: %{"id" => participant.id},
          children: [
            %Xmlel{
              name: "participant",
              attrs: %{"xmlns" => "urn:xmpp:mix:core:1"},
              children: [
                %Xmlel{name: "nick", children: [participant.nick]},
                %Xmlel{name: "jid", children: [participant.jid]}
              ]
            }
          ]
        }
      end
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
