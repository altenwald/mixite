defmodule Mixite.Xmpp.PubsubController do
  use Exampple.Component

  import Mixite.Xmpp.ErrorController, only: [send_not_found: 1]

  alias Exampple.Router.Conn
  alias Exampple.Xml.Xmlel
  alias Exampple.Xmpp.Jid
  alias Mixite.Channel

  def get(conn, [%Xmlel{children: [%Xmlel{attrs: %{"node" => node}}]}]) do
    process_node(conn, node)
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
    if channel = Channel.get(channel_id) do
      item = %Xmlel{
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

      conn
      |> iq_resp([pubsub("urn:xmpp:mix:nodes:config", [item])])
      |> send()
    else
      send_not_found(conn)
    end
  end

  def process_node(%Conn{to_jid: %Jid{node: channel_id}} = conn, "urn:xmpp:mix:nodes:info")
      when channel_id != "" do
    if channel = Channel.get(channel_id) do
      item = %Xmlel{
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

      conn
      |> iq_resp([pubsub("urn:xmpp:mix:nodes:info", [item])])
      |> send()
    else
      send_not_found(conn)
    end
  end

  def process_node(
        %Conn{to_jid: %Jid{node: channel_id}} = conn,
        "urn:xmpp:mix:nodes:participants"
      )
      when channel_id != "" do
    if channel = Channel.get(channel_id) do
      items =
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

      conn
      |> iq_resp([pubsub("urn:xmpp:mix:nodes:participants", items)])
      |> send()
    else
      send_not_found(conn)
    end
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
