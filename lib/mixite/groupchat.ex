defmodule Mixite.Groupchat do
  defmacro __using__(_opts) do
    quote do
      @behaviour Mixite.Groupchat
    end
  end

  alias Exampple.Xmpp.Jid

  @type mix_node() :: :presence | :participants | :messages | :config

  @type t() :: %__MODULE__{
    id: String.t(),
    name: String.t(),
    description: String.t(),
    nodes: [mix_node()],
    contact: [String.t()],
    participants: [participant()],
    updated_at: NaiveDateTime.t(),
    inserted_at: NaiveDateTime.t()
  }

  @type id :: String.t()
  @type user_id :: String.t()
  @type nick :: String.t()

  @type participant_id() :: String.t
  @type participant() :: {user_id(), nick(), Jid.t()}

  @typedoc """
  The nodes are values which are going to be in use with the full
  namespace. The possible node values are:

  ```
  "presence" || "participants" || "messages" || "config" || "info"
  ```

  They are prefixed with: `urn:xmpp:mix:nodes:`.
  """
  @type nodes() :: String.t

  @callback get(t()) :: t() | nil
  @callback join(t(), user_id(), nick(), [nodes()]) :: {participant_id(), [nodes()]}
  @callback update(t(), user_id(), add :: [nodes()], rem :: [nodes()]) :: boolean()

  defstruct [
    id: "",
    name: "",
    description: "",
    nodes: [:presence, :participants, :messages, :config],
    contact: [],
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
    backend = Application.get_env(:mixite, :groupchat, Mixite.DummyGroupchat)
    quote do
      unquote(backend)
    end
  end

  @spec get(id()) :: Groupchat.t | nil
  def get(id), do: backend().get(id)

  @spec join(t(), user_id(), nick(), [nodes()]) :: {participant_id(), [nodes()]}
  def join(groupchat, user_id, nick, nodes) do
    nodes = nodes -- (nodes -- valid_nodes())
    backend().join(groupchat, user_id, nick, nodes)
  end

  @spec update(t(), user_id(), add :: [nodes()], rem :: [nodes()]) :: boolean()
  def update(groupchat, user_id, add_nodes, rem_nodes) do
    add_nodes = add_nodes -- (add_nodes -- valid_nodes())
    rem_nodes = rem_nodes -- (rem_nodes -- valid_nodes())
    backend().update(groupchat, user_id, add_nodes, rem_nodes)
  end
end
