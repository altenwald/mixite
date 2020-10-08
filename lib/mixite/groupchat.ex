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

  @type nodes() :: :presence | :participants | :messages | :config

  @callback get(id()) :: Groupchat.t | nil
  @callback join(id(), user_id(), nick()) :: {participant_id(), [nodes()]}

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

  def backend() do
    Application.get_env(:mixite, :groupchat, Mixite.DummyGroupchat)
  end

  @spec get(id()) :: Groupchat.t | nil
  def get(id), do: backend().get(id)

  @spec join(id(), user_id(), nick()) :: {participant_id(), [nodes()]}
  def join(id, user_id, nick) do
    backend().join(id, user_id, nick)
  end
end
