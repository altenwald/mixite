defmodule Mixite.Channel do
  defmacro __using__(_opts) do
    quote do
      @behaviour Mixite.Channel
      alias Mixite.{Channel, Participant}
    end
  end

  alias Exampple.Xml.Xmlel
  alias Mixite.{Channel, Participant}

  @type mix_node() :: :presence | :participants | :messages | :config

  @type t() :: %__MODULE__{
    id: String.t(),
    name: String.t(),
    description: String.t(),
    nodes: [mix_node()],
    contact: [String.t()],
    owners: [user_jid()],
    participants: [Participant.t()],
    updated_at: NaiveDateTime.t(),
    inserted_at: NaiveDateTime.t()
  }

  @type id :: String.t()
  @type user_jid :: String.t()
  @type user_id :: String.t()
  @type nick :: String.t()

  @typedoc """
  The nodes are values which are going to be in use with the full
  namespace. The possible node values are:

  ```
  "presence" || "participants" || "messages" || "config" || "info"
  ```

  They are prefixed with: `urn:xmpp:mix:nodes:`.
  """
  @type nodes() :: String.t()

  @callback get(t()) :: t() | nil
  @callback join(t(), user_jid(), nick(), [nodes()]) :: {Participant.t(), [nodes()]}
  @callback update(t(), user_jid(), add :: [nodes()], rem :: [nodes()]) :: boolean()
  @callback leave(t(), user_jid()) :: boolean()
  @callback set_nick(t(), user_jid(), nick()) :: :ok | {:error, Atom.t()}
  @callback store_message(t(), [Xmlel.t()]) :: binary()
  @callback create(id(), user_jid()) :: t()

  defstruct [
    id: "",
    name: "",
    description: "",
    nodes: [:presence, :participants, :messages, :config],
    contact: [],
    owners: [],
    participants: [],
    updated_at: NaiveDateTime.utc_now(),
    inserted_at: NaiveDateTime.utc_now()
  ]

  def valid_nodes() do
    ~w[
      config
      info
      messages
      participants
      presence
    ]
  end

  defmacro backend() do
    backend = Application.get_env(:mixite, :channel, Mixite.DummyChannel)
    quote do
      unquote(backend)
    end
  end

  if Mix.env() == :test do
    def gen_uuid, do: Application.get_env(:mixite, :uuid_value, "uuid")
  else
    def gen_uuid, do: UUID.uuid4()
  end

  @spec is_participant_or_owner?(t(), user_jid()) :: boolean()
  def is_participant_or_owner?(channel, jid) do
    is_participant?(channel, jid) or is_owner?(channel, jid)
  end

  @spec is_owner?(t(), user_jid()) :: boolean()
  def is_owner?(%Channel{owners: owners}, jid), do: jid in owners

  @spec is_participant?(t(), user_jid()) :: boolean()
  def is_participant?(%Channel{participants: participants}, jid) do
    Enum.any?(participants, fn %Participant{jid: part_jid} -> part_jid == jid end)
  end

  @spec get_participant(t(), user_jid()) :: Participant.t() | nil
  def get_participant(%Channel{participants: participants}, jid) do
    Enum.find(participants, fn %Participant{jid: part_jid} -> part_jid == jid end)
  end

  @spec split(t(), user_jid()) :: {Participant.t() | nil, t()}
  def split(%Channel{participants: participants} = channel, jid) do
    filter = fn %Participant{jid: user_jid} -> user_jid == jid end
    case Enum.split_with(participants, filter) do
      {[], _participants} ->
        {nil, channel}

      {[participant], participants} ->
        {participant, %Channel{channel | participants: participants}}
    end
  end

  @spec get(id()) :: Channel.t | nil
  def get(id), do: backend().get(id)

  @spec join(t(), user_jid(), nick(), [nodes()]) :: {Participant.t(), [nodes()]}
  def join(channel, user_jid, nick, nodes) do
    nodes = nodes -- (nodes -- valid_nodes())
    backend().join(channel, user_jid, nick, nodes)
  end

  @spec update(t(), user_jid(), add :: [nodes()], rem :: [nodes()]) :: boolean()
  def update(channel, user_jid, add_nodes, rem_nodes) do
    add_nodes = add_nodes -- (add_nodes -- valid_nodes())
    rem_nodes = rem_nodes -- (rem_nodes -- valid_nodes())
    backend().update(channel, user_jid, add_nodes, rem_nodes)
  end

  @spec leave(t(), user_jid()) :: boolean()
  def leave(channel, user_jid) do
    backend().leave(channel, user_jid)
  end

  @spec set_nick(t(), user_jid(), nick()) :: :ok | {:error, Atom.t()}
  def set_nick(channel, user_jid, nick) do
    backend().set_nick(channel, user_jid, nick)
  end

  @spec store_message(t(), [Xmlel.t()]) :: binary()
  def store_message(channel, payload) do
    backend().store_message(channel, payload)
  end

  @spec create(id(), user_jid()) :: t()
  def create(id, user_jid) do
    backend().create(id, user_jid)
  end
end
