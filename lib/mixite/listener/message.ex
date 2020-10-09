defmodule Mixite.Listener.Message do
  use GenStage

  alias Exampple.Component
  alias Exampple.Xml.Xmlel
  alias Exampple.Xmpp.Stanza

  @producer Mixite.EventManager

  def start_link(args) do
    GenStage.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl GenStage
  def init(_args) do
    {:consumer, [], subscribe_to: [@producer]}
  end

  @impl GenStage
  def handle_events([{:join, id, from_jid, user_jid, nick, groupchat}], _from, state) do
    payload =
      %Xmlel{
        name: "event",
        attrs: %{"xmlns" => "http://jabber.org/protocol/pubsub#event"},
        children: [
          %Xmlel{
            name: "items",
            attrs: %{"node" => "urn:xmpp:mix:nodes:participants"},
            children: [
              %Xmlel{
                name: "item",
                attrs: %{"id" => id},
                children: [
                  %Xmlel{
                    name: "participant",
                    attrs: %{"xmlns" => "urn:xmpp:mix:core:1"},
                    children: [
                      %Xmlel{name: "jid", children: [user_jid]},
                      %Xmlel{name: "nick", children: [nick]}
                    ]
                  }
                ]
              }
            ]
          }
        ]
      }

    [{id, nick, user_jid} | groupchat.participants]
    |> Enum.each(fn {_id, _nick, jid} ->
      [payload]
      |> Stanza.message(from_jid, gen_uuid(), jid)
      |> Component.send()
    end)

    {:noreply, [], state}
  end

  if Mix.env() == :test do
    def gen_uuid, do: "uuid"
  else
    def gen_uuid, do: UUID.uuid4()
  end
end
