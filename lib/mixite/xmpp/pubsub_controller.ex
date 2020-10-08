defmodule Mixite.Xmpp.PubsubController do
  use Exampple.Component

  import Exampple.Xml.Xmlel, only: [sigil_x: 2]
  import Mixite.Xmpp.ErrorController, only: [send_not_found: 1]

  alias Exampple.Router.Conn
  alias Exampple.Xml.Xmlel
  alias Exampple.Xmpp.Jid
  alias Mixite.Groupchat

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

  def process_node(%Conn{to_jid: %Jid{node: channel}} = conn, "urn:xmpp:mix:nodes:info") when channel != "" do
    if groupchat = Groupchat.get(channel) do
      item =
        %Xmlel{
          name: "item",
          attrs: %{"id" => to_string(groupchat.updated_at)},
          children: [
            %Xmlel{
              name: "x",
              attrs: %{"xmlns" => "jabber:x:data", "type" => "result"},
              children:
                field("FORM_TYPE", "hidden", "urn:xmpp:mix:core:1") ++
                field("Name", groupchat.name) ++
                field("Description", groupchat.description) ++
                field("Contact", groupchat.contact)
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

  def process_node(%Conn{to_jid: %Jid{node: channel}} = conn, "urn:xmpp:mix:nodes:participants") when channel != "" do
    if groupchat = Groupchat.get(channel) do
      items =
        for {id, nick, jid} <- groupchat.participants do
          %Xmlel{
            name: "item",
            attrs: %{"id" => id},
            children: [
              %Xmlel{
                name: "participant",
                attrs: %{"xmlns" => "urn:xmpp:mix:core:1"},
                children: [
                  %Xmlel{name: "nick", children: [nick]},
                  %Xmlel{name: "jid", children: [jid]}
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
