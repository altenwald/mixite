defmodule Mixite.Channel do
  defmacro __using__(_opts) do
    quote do
      @behaviour Mixite.Channel
      alias Mixite.{Channel, Participant}

      @impl Channel
      def join(_channel, _jid, _nick, _nodes) do
        {:error, :not_implemented}
      end

      @impl Channel
      def update_subscription(_channel, _user_id, _add_nodes, _rem_nodes) do
        {:error, :not_implemented}
      end

      @impl Channel
      def leave(_channel, _user_jid) do
        {:error, :not_implemented}
      end

      @impl Channel
      def set_nick(_channel, _user_jid, _nick) do
        {:error, :not_implemented}
      end

      @impl Channel
      def store_message(_channel, _query) do
        {:error, :not_implemented}
      end

      @impl Channel
      def create(_id, _user_jid) do
        {:error, :not_implemented}
      end

      @impl Channel
      def update(_channel, _params, _ns) do
        {:error, :not_implemented}
      end

      @impl Channel
      def destroy(_channel, _user_jid) do
        {:error, :not_implemented}
      end

      @impl Channel
      def config_params(_channel) do
        %{}
      end

      @impl Channel
      def info_params(_channel) do
        %{}
      end

      @impl Channel
      def valid_nodes() do
        ~w[
          config
          info
          messages
          participants
          presence
        ]
      end

      defoverridable join: 4,
                     update_subscription: 4,
                     leave: 2,
                     set_nick: 3,
                     store_message: 2,
                     create: 2,
                     update: 3,
                     destroy: 2,
                     config_params: 1,
                     info_params: 1,
                     valid_nodes: 0
    end
  end

  require Logger

  alias Exampple.Xml.Xmlel
  alias Mixite.{Channel, Participant}

  @type mix_node() :: :presence | :participants | :messages | :config | :info

  @type t() :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          description: String.t(),
          nodes: [mix_node()],
          contact: [String.t()],
          owners: [user_jid()],
          administrators: [user_jid()],
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

  @callback get(id()) :: t() | nil
  @callback list_by_jid(user_jid()) :: [t()]
  @callback config_params(t()) :: %{
              (String.t() | {String.t(), String.t()}) => String.t() | [String.t()]
            }
  @callback info_params(t()) :: %{
              (String.t() | {String.t(), String.t()}) => String.t() | [String.t()]
            }
  @callback join(t(), user_jid(), nick(), [nodes()]) ::
              {:ok, {Participant.t(), [nodes()]}} | {:error, Atom.t()}
  @callback update_subscription(t(), user_jid(), add :: [nodes()], rem :: [nodes()]) ::
              {:ok, {t(), add :: [nodes()], rem :: [nodes()]}} | {:error, Atom.t()}
  @callback leave(t(), user_jid()) :: :ok | {:error, Atom.t()}
  @callback set_nick(t(), user_jid(), nick()) :: :ok | {:error, Atom.t()}
  @callback store_message(t(), Xmlel.t()) :: {:ok, String.t() | nil} | {:error, Atom.t()}
  @callback create(id(), user_jid()) :: {:ok, t()} | {:error, Atom.t()}
  @callback update(t(), Map.t(), nodes()) :: {:ok, t()} | {:error, Atom.t()}
  @callback destroy(t(), user_jid()) :: :ok | {:error, Atom.t()}
  @callback valid_nodes() :: [nodes()]

  defstruct id: "",
            name: "",
            description: "",
            nodes: ~w[ presence participants messages config ]a,
            contact: [],
            owners: [],
            administrators: [],
            participants: [],
            updated_at: NaiveDateTime.utc_now(),
            inserted_at: NaiveDateTime.utc_now()

  @doc """
  Get the backend implementation for Mixite.

  Examples:

      iex> require Mixite.Channel
      iex> Mixite.Channel.backend()
      Mixite.DummyChannel
  """
  defmacro backend() do
    backend = Application.get_env(:mixite, :channel, Mixite.DummyChannel)

    quote do
      unquote(backend)
    end
  end

  def gen_uuid, do: Application.get_env(:mixite, :uuid_value, UUID.uuid4())

  @doc """
  Let us know if a JID is part of the participants or owners for the channel.

  Examples:
      iex> p1 = %Mixite.Participant{jid: "user1@example.com"}
      iex> p2 = %Mixite.Participant{jid: "user2@example.com"}
      iex> p3 = %Mixite.Participant{jid: "user3@example.com"}
      iex> participants = [p1, p2, p3]
      iex> %Mixite.Channel{participants: participants, owners: ["user3@example.com"]}
      iex> |> Mixite.Channel.is_participant_or_owner?("user3@example.com")
      true

      iex> p1 = %Mixite.Participant{jid: "user1@example.com"}
      iex> p2 = %Mixite.Participant{jid: "user2@example.com"}
      iex> p3 = %Mixite.Participant{jid: "user3@example.com"}
      iex> participants = [p1, p2, p3]
      iex> %Mixite.Channel{participants: participants, owners: ["user3@example.com"]}
      iex> |> Mixite.Channel.is_participant_or_owner?("user2@example.com")
      true

      iex> p1 = %Mixite.Participant{jid: "user1@example.com"}
      iex> p2 = %Mixite.Participant{jid: "user2@example.com"}
      iex> p3 = %Mixite.Participant{jid: "user3@example.com"}
      iex> participants = [p1, p2, p3]
      iex> %Mixite.Channel{participants: participants}
      iex> |> Mixite.Channel.is_participant_or_owner?("user4@example.com")
      false
  """
  @spec is_participant_or_owner?(t(), user_jid()) :: boolean()
  def is_participant_or_owner?(channel, jid) do
    is_participant?(channel, jid) or is_owner?(channel, jid)
  end

  @doc """
  Let us know if a JID is part of the administrators or owners for the channel.

  Examples:
      iex> p1 = %Mixite.Participant{jid: "user1@example.com"}
      iex> p2 = %Mixite.Participant{jid: "user2@example.com"}
      iex> p3 = %Mixite.Participant{jid: "user3@example.com"}
      iex> participants = [p1, p2, p3]
      iex> %Mixite.Channel{participants: participants, administrators: ["user3@example.com"]}
      iex> |> Mixite.Channel.is_administrator_or_owner?("user3@example.com")
      true

      iex> p1 = %Mixite.Participant{jid: "user1@example.com"}
      iex> p2 = %Mixite.Participant{jid: "user2@example.com"}
      iex> p3 = %Mixite.Participant{jid: "user3@example.com"}
      iex> participants = [p1, p2, p3]
      iex> %Mixite.Channel{participants: participants, owners: ["user3@example.com"]}
      iex> |> Mixite.Channel.is_administrator_or_owner?("user3@example.com")
      true

      iex> p1 = %Mixite.Participant{jid: "user1@example.com"}
      iex> p2 = %Mixite.Participant{jid: "user2@example.com"}
      iex> p3 = %Mixite.Participant{jid: "user3@example.com"}
      iex> participants = [p1, p2, p3]
      iex> %Mixite.Channel{participants: participants}
      iex> |> Mixite.Channel.is_administrator_or_owner?("user1@example.com")
      false
  """
  @spec is_administrator_or_owner?(t(), user_jid()) :: boolean()
  def is_administrator_or_owner?(channel, jid) do
    is_administrator?(channel, jid) or is_owner?(channel, jid)
  end

  @doc """
  Let us know if a JID is part of the owners for the channel.

  Examples:
      iex> p1 = %Mixite.Participant{jid: "user1@example.com"}
      iex> p2 = %Mixite.Participant{jid: "user2@example.com"}
      iex> p3 = %Mixite.Participant{jid: "user3@example.com"}
      iex> participants = [p1, p2, p3]
      iex> %Mixite.Channel{participants: participants, owners: ["user3@example.com"]}
      iex> |> Mixite.Channel.is_owner?("user3@example.com")
      true

      iex> p1 = %Mixite.Participant{jid: "user1@example.com"}
      iex> p2 = %Mixite.Participant{jid: "user2@example.com"}
      iex> p3 = %Mixite.Participant{jid: "user3@example.com"}
      iex> participants = [p1, p2, p3]
      iex> %Mixite.Channel{participants: participants}
      iex> |> Mixite.Channel.is_owner?("user1@example.com")
      false
  """
  @spec is_owner?(t(), user_jid()) :: boolean()
  def is_owner?(%Channel{owners: owners}, jid), do: jid in owners

  @doc """
  Let us know if a JID is part of the administrators for the channel.

  Examples:
      iex> p1 = %Mixite.Participant{jid: "user1@example.com"}
      iex> p2 = %Mixite.Participant{jid: "user2@example.com"}
      iex> p3 = %Mixite.Participant{jid: "user3@example.com"}
      iex> participants = [p1, p2, p3]
      iex> %Mixite.Channel{participants: participants, administrators: ["user3@example.com"]}
      iex> |> Mixite.Channel.is_administrator?("user3@example.com")
      true

      iex> p1 = %Mixite.Participant{jid: "user1@example.com"}
      iex> p2 = %Mixite.Participant{jid: "user2@example.com"}
      iex> p3 = %Mixite.Participant{jid: "user3@example.com"}
      iex> participants = [p1, p2, p3]
      iex> %Mixite.Channel{participants: participants}
      iex> |> Mixite.Channel.is_administrator?("user1@example.com")
      false
  """
  @spec is_administrator?(t(), user_jid()) :: boolean()
  def is_administrator?(%Channel{administrators: administrators}, jid) do
    jid in administrators
  end

  @doc """
  Let us know if it's a participant or not.

  Examples:
      iex> p1 = %Mixite.Participant{jid: "user1@example.com"}
      iex> p2 = %Mixite.Participant{jid: "user2@example.com"}
      iex> p3 = %Mixite.Participant{jid: "user3@example.com"}
      iex> participants = [p1, p2, p3]
      iex> %Mixite.Channel{participants: participants}
      iex> |> Mixite.Channel.is_participant?("user3@example.com")
      true

      iex> p1 = %Mixite.Participant{jid: "user1@example.com"}
      iex> p2 = %Mixite.Participant{jid: "user2@example.com"}
      iex> p3 = %Mixite.Participant{jid: "user3@example.com"}
      iex> participants = [p1, p2, p3]
      iex> %Mixite.Channel{participants: participants}
      iex> |> Mixite.Channel.is_participant?("user4@example.com")
      false
  """
  @spec is_participant?(t(), user_jid()) :: boolean()
  def is_participant?(%Channel{participants: participants}, jid) do
    Enum.any?(participants, fn %Participant{jid: part_jid} -> part_jid == jid end)
  end

  @doc """
  Let us know if the user can view the information for the channel.

  Examples:
      iex> p1 = %Mixite.Participant{jid: "user1@example.com"}
      iex> p2 = %Mixite.Participant{jid: "user2@example.com"}
      iex> p3 = %Mixite.Participant{jid: "user3@example.com"}
      iex> participants = [p1, p2, p3]
      iex> %Mixite.Channel{participants: participants}
      iex> |> Mixite.Channel.can_view?("user3@example.com")
      true

      iex> p1 = %Mixite.Participant{jid: "user1@example.com"}
      iex> p2 = %Mixite.Participant{jid: "user2@example.com"}
      iex> p3 = %Mixite.Participant{jid: "user3@example.com"}
      iex> participants = [p1, p2, p3]
      iex> %Mixite.Channel{participants: participants}
      iex> |> Mixite.Channel.can_view?("user4@example.com")
      false
  """
  @spec can_view?(t(), user_jid()) :: boolean()
  def can_view?(channel, jid) do
    is_participant_or_owner?(channel, jid) or is_administrator?(channel, jid)
  end

  @doc """
  Let us know if the user can modify the information for the channel.

  Examples:
      iex> p1 = "user1@example.com"
      iex> p2 = "user2@example.com"
      iex> p3 = "user3@example.com"
      iex> admins = [p1, p2, p3]
      iex> %Mixite.Channel{administrators: admins}
      iex> |> Mixite.Channel.can_modify?("user3@example.com")
      true

      iex> p1 = "user1@example.com"
      iex> p2 = "user2@example.com"
      iex> p3 = "user3@example.com"
      iex> admins = [p1, p2, p3]
      iex> %Mixite.Channel{administrators: admins}
      iex> |> Mixite.Channel.can_modify?("user4@example.com")
      false
  """
  @spec can_modify?(t(), user_jid()) :: boolean()
  def can_modify?(channel, jid) do
    is_administrator_or_owner?(channel, jid)
  end

  @doc """
  Get a participant from a channel if it exists.

  Examples:
      iex> p1 = %Mixite.Participant{jid: "user1@example.com"}
      iex> p2 = %Mixite.Participant{jid: "user2@example.com"}
      iex> p3 = %Mixite.Participant{jid: "user3@example.com"}
      iex> participants = [p1, p2, p3]
      iex> %Mixite.Channel{participants: participants}
      iex> |> Mixite.Channel.get_participant("user3@example.com")
      %Mixite.Participant{jid: "user3@example.com"}

      iex> p1 = %Mixite.Participant{jid: "user1@example.com"}
      iex> p2 = %Mixite.Participant{jid: "user2@example.com"}
      iex> p3 = %Mixite.Participant{jid: "user3@example.com"}
      iex> participants = [p1, p2, p3]
      iex> %Mixite.Channel{participants: participants}
      iex> |> Mixite.Channel.get_participant("user4@example.com")
      nil
  """
  @spec get_participant(t(), user_jid()) :: Participant.t() | nil
  def get_participant(%Channel{participants: participants}, jid) do
    Enum.find(participants, fn %Participant{jid: part_jid} -> part_jid == jid end)
  end

  @doc """
  Split participant with the given `user_jid` from the rest of the
  participants.

  Examples:
      iex> p1 = %Mixite.Participant{jid: "user1@example.com"}
      iex> p2 = %Mixite.Participant{jid: "user2@example.com"}
      iex> p3 = %Mixite.Participant{jid: "user3@example.com"}
      iex> participants = [p1, p2, p3]
      iex> %Mixite.Channel{participants: participants}
      iex> |> Mixite.Channel.split("user2@example.com")
      {%Mixite.Participant{jid: "user2@example.com"},
       %Mixite.Channel{participants: [
         %Mixite.Participant{jid: "user1@example.com"},
         %Mixite.Participant{jid: "user3@example.com"}]}}
  """
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

  @spec get(id()) :: t() | nil
  def get(id), do: backend().get(id)

  @spec list_by_jid(user_jid()) :: [t()]
  def list_by_jid(jid), do: backend().list_by_jid(jid)

  @spec config_params(t()) :: %{String.t() => String.t() | [String.t()]}
  def config_params(channel), do: backend().config_params(channel)

  @spec info_params(t()) :: %{String.t() => String.t() | [String.t()]}
  def info_params(channel), do: backend().info_params(channel)

  @spec join(t(), user_jid(), nick(), [nodes()]) ::
          {:ok, {Participant.t(), [nodes()]}} | {:error, Atom.t()}
  def join(channel, user_jid, nick, nodes) do
    nodes = nodes -- nodes -- valid_nodes()
    backend().join(channel, user_jid, nick, nodes)
  end

  @spec update_subscription(t(), user_jid(), add :: [nodes()], rem :: [nodes()]) ::
          {:ok, {t(), add :: [nodes()], rem :: [nodes()]}} | {:error, Atom.t()}
  def update_subscription(channel, user_jid, add_nodes, rem_nodes) do
    add_nodes = (add_nodes -- add_nodes -- valid_nodes()) -- channel.nodes
    rem_nodes = rem_nodes -- rem_nodes -- valid_nodes()
    rem_nodes = rem_nodes -- rem_nodes -- channel.nodes
    Logger.debug("channel nodes: #{inspect(channel.nodes)}")
    Logger.debug("remove nodes: #{inspect(rem_nodes)}")
    Logger.debug("add nodes: #{inspect(add_nodes)}")

    case backend().update_subscription(channel, user_jid, add_nodes, rem_nodes) do
      {:error, _} = error -> error
      {:ok, channel} -> {:ok, {channel, add_nodes, rem_nodes}}
    end
  end

  @spec leave(t(), user_jid()) :: :ok | {:error, Atom.t()}
  def leave(channel, user_jid) do
    backend().leave(channel, user_jid)
  end

  @spec set_nick(t(), user_jid(), nick()) :: :ok | {:error, Atom.t()}
  def set_nick(channel, user_jid, nick) do
    backend().set_nick(channel, user_jid, nick)
  end

  @spec store_message(t(), Xmlel.t()) :: {:ok, String.t() | nil} | {:error, Atom.t()}
  def store_message(channel, message) do
    backend().store_message(channel, message)
  end

  @spec create(id(), user_jid()) :: {:ok, t()} | {:error, Atom.t()}
  def create(id, user_jid) do
    backend().create(id, user_jid)
  end

  @spec update(t(), Map.t(), nodes()) :: {:ok, t()} | {:error, Atom.t()}
  def update(channel, params, ns_node) do
    backend().update(channel, params, ns_node)
  end

  @spec destroy(t(), user_jid()) :: :ok | {:error, Atom.t()}
  def destroy(channel, user_jid) do
    backend().destroy(channel, user_jid)
  end

  def valid_nodes() do
    backend().valid_nodes()
  end

  defimpl String.Chars, for: __MODULE__ do
    @doc """
    Convert channel into a string representation.

    Examples:
        iex> %Mixite.Channel{id: "ID"}
        iex> |> to_string()
        "#Channel<id:ID>"
    """
    def to_string(%Channel{id: id}), do: "#Channel<id:#{id}>"
  end
end
