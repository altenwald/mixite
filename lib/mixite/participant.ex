defmodule Mixite.Participant do
  @moduledoc """
  Participant gives information about a member of a channel
  which is subscribed to a specific node.
  """

  alias Mixite.{Channel, Participant}

  @type t() :: %{
    id: String.t(),
    jid: Channel.user_jid(),
    nick: String.t(),
    nodes: [Channel.nodes()]
  }

  defstruct [
    id: nil,
    jid: nil,
    nick: nil,
    nodes: []
  ]

  def new(id \\ nil, jid, nick, nodes) do
    %Participant{
      id: id || Channel.gen_uuid(),
      jid: jid,
      nick: nick,
      nodes: nodes
    }
  end

  defimpl String.Chars, for: __MODULE__ do
    def to_string(%Participant{jid: jid}), do: "#Participant<jid:#{jid}>"
  end
end
