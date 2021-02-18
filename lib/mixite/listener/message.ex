defmodule Mixite.Listener.Message do
  use GenStage

  alias Exampple.Xml.Xmlel
  alias Mixite.{Broadcast, Channel, Participant, Pubsub}

  @producer Mixite.EventManager

  @ns_participants "urn:xmpp:mix:nodes:participants"

  def start_link(args) do
    GenStage.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl GenStage
  def init(_args) do
    {:consumer, [], subscribe_to: [@producer]}
  end

  @impl GenStage
  def handle_events([{:set_nick, nick, participant, mix_jid, user_jid, channel}], _from, state) do
    participants =
      (channel.participants -- [participant]) ++
        [%Mixite.Participant{participant | nick: nick}]

    channel = %Channel{channel | participants: participants}
    items = Pubsub.render(channel, @ns_participants, only_jids: [user_jid])
    payload = Pubsub.wrapper(:event, @ns_participants, items)
    Broadcast.send(channel, user_jid, [payload], mix_jid, ignore_jids: [user_jid])
    {:noreply, [], state}
  end

  def handle_events([{:leave, id, from_jid, user_jid, channel}], _from, state) do
    payload =
      Pubsub.wrapper(:event, @ns_participants, [
        Xmlel.new("retract", %{"id" => id}, [
          Xmlel.new("jid", %{}, [user_jid])
        ])
      ])

    Broadcast.send(channel, user_jid, [payload], from_jid, ignore_jids: [user_jid])
    {:noreply, [], state}
  end

  def handle_events([{:join, id, from_jid, user_jid, nick, channel}], _from, state) do
    channel = %Channel{
      participants: [%Participant{id: id, jid: user_jid, nick: nick} | channel.participants]
    }

    items = Pubsub.render(channel, @ns_participants, only_jids: [user_jid])
    payload = Pubsub.wrapper(:event, @ns_participants, items)

    Broadcast.send(channel, user_jid, [payload], from_jid, ignore_jids: [user_jid])
    {:noreply, [], state}
  end
end
