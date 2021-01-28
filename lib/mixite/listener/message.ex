defmodule Mixite.Listener.Message do
  use GenStage

  alias Exampple.Component
  alias Exampple.Xml.Xmlel
  alias Exampple.Xmpp.Stanza
  alias Mixite.{Channel, Participant}

  @producer Mixite.EventManager

  def start_link(args) do
    GenStage.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl GenStage
  def init(_args) do
    {:consumer, [], subscribe_to: [@producer]}
  end

  @impl GenStage
  def handle_events([{:broadcast, _from_jid, _channel, _payload}], _from, state) do
    {:noreply, [], state}
  end

  def handle_events([{:leave, id, from_jid, user_jid, channel}], _from, state) do
    payload =
      build_node(%Xmlel{
        name: "retract",
        attrs: %{"id" => id},
        children: [
          %Xmlel{name: "jid", children: [user_jid]}
        ]
      })

    channel.participants
    |> Enum.each(fn %Participant{jid: jid} ->
      [payload]
      |> Stanza.message(from_jid, Channel.gen_uuid(), jid)
      |> Component.send()
    end)

    {:noreply, [], state}
  end

  def handle_events([{:join, id, from_jid, user_jid, nick, channel}], _from, state) do
    payload =
      build_node(%Xmlel{
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
      })

    [%Participant{jid: user_jid} | channel.participants]
    |> Enum.each(fn %Participant{jid: jid} ->
      [payload]
      |> Stanza.message(from_jid, Channel.gen_uuid(), jid)
      |> Component.send()
    end)

    {:noreply, [], state}
  end

  defp build_node(%Xmlel{} = child) do
    %Xmlel{
      name: "event",
      attrs: %{"xmlns" => "http://jabber.org/protocol/pubsub#event"},
      children: [
        %Xmlel{
          name: "items",
          attrs: %{"node" => "urn:xmpp:mix:nodes:participants"},
          children: [child]
        }
      ]
    }
  end
end
