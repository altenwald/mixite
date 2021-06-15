defmodule Mixite.Broadcast do
  alias Exampple.Component
  alias Exampple.Xml.Xmlel
  alias Exampple.Xmpp.Stanza
  alias Mixite.{Channel, Participant}

  defmacro __using__(_params) do
    quote do
      @behaviour Mixite.Broadcast
      alias Mixite.Broadcast

      @impl Broadcast
      def extra_payload(_channel, _user_jid, _from_jid, payload, _opts) do
        payload
      end

      @impl Broadcast
      def filter(message, _channel, _user_jid, _jid, _opts) do
        message
      end

      defoverridable extra_payload: 5, filter: 5
    end
  end

  @callback extra_payload(
              Channel.t(),
              Channel.user_jid(),
              Channel.user_jid(),
              [Xmlel.t()],
              Keyword.t()
            ) :: [Xmlel.t()]

  @doc """
  Get the backend implementation for Mixite.

  Examples:

      iex> require Mixite.Broadcast
      iex> Mixite.Broadcast.backend()
      Mixite.DummyBroadcast
  """
  defmacro backend() do
    backend = Application.get_env(:mixite, :broadcast, Mixite.DummyBroadcast)

    quote do
      unquote(backend)
    end
  end

  @spec maybe_extra_payload(
          Channel.t(),
          Channel.user_jid(),
          Channel.user_jid(),
          [Xmlel.t()],
          Keyword.t()
        ) :: [Xmlel.t()] | :drop
  defp maybe_extra_payload(channel, user_jid, from_jid, payload, opts) do
    backend().extra_payload(channel, user_jid, from_jid, payload, opts)
  end

  defp maybe_send(message, channel, user_jid, jid, opts) do
    case backend().filter(message, channel, user_jid, jid, opts) do
      :drop -> :ok
      message -> Component.send(message)
    end
  end

  def send(%Channel{} = channel, user_jid, payload, from_jid, opts \\ []) do
    ignore_jids = opts[:ignore_jids] || []

    type =
      case opts[:type] do
        "normal" -> nil
        type -> type
      end

    message_id =
      case opts[:id] do
        nil -> Channel.gen_uuid()
        id -> id
      end

    case maybe_extra_payload(channel, user_jid, from_jid, payload, opts) do
      :drop ->
        :ok

      payload ->
        channel.participants
        |> Enum.reject(&(&1.jid in ignore_jids))
        |> Enum.each(fn %Participant{jid: jid} ->
          payload
          |> Stanza.message(from_jid, message_id, jid, type)
          |> maybe_send(channel, user_jid, jid, opts)
        end)
    end
  end
end
