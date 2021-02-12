defmodule Mixite.Broadcast do
  alias Exampple.Component
  alias Exampple.Xmpp.Stanza
  alias Mixite.{Channel, EventManager, Participant}

  def send(channel, payload, from_jid, type \\ "groupchat", ignore_jids \\ []) do
    EventManager.notify({:broadcast, from_jid, channel, payload})

    message_id = Channel.gen_uuid()

    channel.participants
    |> Enum.reject(& &1.jid in ignore_jids)
    |> Enum.each(fn %Participant{jid: jid} ->
      payload
      |> Stanza.message(from_jid, message_id, jid, type)
      |> Component.send()
    end)
  end
end
