defmodule Mixite.Broadcast do
  alias Exampple.Component
  alias Exampple.Xml.Xmlel
  alias Exampple.Xmpp.Stanza
  alias Mixite.{Channel, Participant}

  import Exampple.Xml.Xmlel, only: [sigil_x: 2]

  def send(channel, payload, from_jid, opts \\ []) do
    ignore_jids = opts[:ignore_jids] || []
    type = opts[:type]

    message_id = Channel.gen_uuid()
    payload = payload ++ extra_payload()

    channel.participants
    |> Enum.reject(&(&1.jid in ignore_jids))
    |> Enum.each(fn %Participant{jid: jid} ->
      payload
      |> Stanza.message(from_jid, message_id, jid, type)
      |> Component.send()
    end)
  end

  @doc """
  Get extra payload to be add to the broadcast messages.

  Examples:
      iex> Application.put_env(:mixite, :extra_payload, "<store/>")
      iex> Mixite.Broadcast.extra_payload()
      [%Exampple.Xml.Xmlel{name: "store"}]

      iex> Application.put_env(:mixite, :extra_payload, [])
      iex> Mixite.Broadcast.extra_payload()
      []

      iex> Application.put_env(:mixite, :extra_payload, %Exampple.Xml.Xmlel{name: "archive"})
      iex> Mixite.Broadcast.extra_payload()
      [%Exampple.Xml.Xmlel{name: "archive"}]

      iex> Application.put_env(:mixite, :extra_payload, [%Exampple.Xml.Xmlel{name: "stanza-id"}])
      iex> Mixite.Broadcast.extra_payload()
      [%Exampple.Xml.Xmlel{name: "stanza-id"}]
  """
  def extra_payload() do
    case Application.get_env(:mixite, :extra_payload, []) do
      [] -> []
      xmlel when is_binary(xmlel) -> [~x[#{xmlel}]]
      %Xmlel{} = xmlel -> [xmlel]
      [%Xmlel{} | _] = xmlel -> xmlel
    end
  end
end
