defmodule Mixite.Pubsub do
  use Mixite.Namespaces
  alias Exampple.Xml.Xmlel
  alias Mixite.Channel

  defmacro __using__(_params) do
    quote do
      alias Mixite.Pubsub
      @behaviour Pubsub

      @impl Pubsub
      def process_get_node(_channel_id, _user_jid, _node) do
        :ignore
      end

      @impl Pubsub
      def process_set_node(_channel_id, _user_jid, _node, _query) do
        :ignore
      end

      defoverridable process_get_node: 3,
                     process_set_node: 4
    end
  end

  @callback process_get_node(Channel.id(), Channel.user_jid(), Channel.nodes()) ::
              :ignore
              | {:error, {String.t(), String.t(), String.t()}}
              | {:ok, Xmlel.t()}
              | {:ok, [Xmlel.t()]}

  @callback process_set_node(Channel.id(), Channel.user_jid(), Channel.nodes(), Xmlel.t()) ::
              :ignore
              | {:error, {String.t(), String.t(), String.t()}}
              | {:ok, Channel.t(), Xmlel.t()}
              | {:ok, Channel.t(), [Xmlel.t()]}

  @doc """
  Get the backend implementation for Mixite.

  Examples:

      iex> require Mixite.Channel
      iex> Mixite.Channel.backend()
      Mixite.DummyChannel
  """
  defmacro backend() do
    backend = Application.get_env(:mixite, :pubsub, Mixite.DummyPubsub)

    quote do
      unquote(backend)
    end
  end

  @spec process_get_node(Channel.id(), Channel.user_jid(), Channel.nodes()) ::
          :ignore
          | {:error, {String.t(), String.t(), String.t()}}
          | {:ok, Xmlel.t()}
          | {:ok, [Xmlel.t()]}
  def process_get_node(id, user_jid, nodes) do
    backend().process_get_node(id, user_jid, nodes)
  end

  @spec process_set_node(Channel.id(), Channel.user_jid(), Channel.nodes(), Xmlel.t()) ::
          :ignore
          | {:error, {String.t(), String.t(), String.t()}}
          | {:ok, Channel.t(), Xmlel.t()}
          | {:ok, Channel.t(), [Xmlel.t()]}
  def process_set_node(id, user_jid, nodes, query) do
    backend().process_set_node(id, user_jid, nodes, query)
  end

  defp field(name, type \\ nil, value)
  defp field(_name, _type, nil), do: []
  defp field(_name, _type, []), do: []

  defp field(name, type, value) when is_atom(value) do
    field(name, type, to_string(value))
  end

  defp field(name, type, value) when is_struct(value, NaiveDateTime) do
    field(name, type, to_string(value))
  end

  defp field(name, type, value) when not is_struct(value, MapSet) do
    children =
      if is_list(value) do
        for v <- value, do: %Xmlel{name: "value", children: [v]}
      else
        [%Xmlel{name: "value", children: [value]}]
      end

    attrs =
      if type do
        %{"var" => name, "type" => type}
      else
        %{"var" => name}
      end

    [%Xmlel{name: "field", attrs: attrs, children: children}]
  end

  defp field(name, type, values) do
    field(name, type, MapSet.to_list(values))
  end

  def render(channel, nodes, opts \\ [])

  def render(channel, @ns_config, _opts) do
    %Xmlel{
      name: "item",
      attrs: %{"id" => Exampple.Xmpp.Timestamp.to_utc_string(channel.updated_at)},
      children: [
        %Xmlel{
          name: "x",
          attrs: %{"xmlns" => @ns_xdata, "type" => "result"},
          children:
            [
              {{"FORM_TYPE", "hidden"}, @ns_admin},
              {"Last Change Made By", channel.last_change_by},
              {"Owner", channel.owners},
              {"Administrator", channel.administrators},
              {"End of Life", channel.end_of_life},
              {"Nodes Present", channel.nodes},
              {"Participants Node Subscription", channel.can_subs_participants},
              {"Information Node Subscription", channel.can_subs_info},
              {"Allowed Node Subscription", channel.can_subs_allowed},
              {"Banned Node Subscription", channel.can_subs_banned},
              {"Configuration Node Access", channel.can_subs_config},
              {"Information Node Update Rights", channel.can_update_info},
              {"Avatar Nodes Update Rights", channel.can_update_avatar},
              {"Mandatory Nicks", channel.mandatory_nicks}
            ]
            |> merge(Enum.to_list(Channel.config_params(channel)))
            |> Enum.flat_map(fn
              {{key, type}, value} -> field(key, type, value)
              {key, value} -> field(key, value)
            end)
        }
      ]
    }
  end

  defp merge(list, []), do: list

  defp merge(list, [{key, value} | list2]) do
    if List.keymember?(list, key, 0) do
      merge(List.keyreplace(list, key, 0, {key, value}), list2)
    else
      merge(list ++ [{key, value}], list2)
    end
  end

  def render(channel, @ns_info, _opts) do
    %Xmlel{
      name: "item",
      attrs: %{"id" => Exampple.Xmpp.Timestamp.to_utc_string(channel.updated_at)},
      children: [
        %Xmlel{
          name: "x",
          attrs: %{"xmlns" => @ns_xdata, "type" => "result"},
          children:
            field("FORM_TYPE", "hidden", @ns_core) ++
              field("Name", channel.name) ++
              field("Description", channel.description) ++
              field("Contact", channel.contact) ++
              Enum.map(Channel.info_params(channel), fn
                {{key, type}, value} -> hd(field(key, type, value))
                {key, value} -> hd(field(key, value))
              end)
        }
      ]
    }
  end

  def render(channel, @ns_participants, opts) do
    only_jids = opts[:only_jids]

    for participant <- channel.participants, is_nil(only_jids) or participant.jid in only_jids do
      %Xmlel{
        name: "item",
        attrs: %{"id" => participant.id},
        children: [
          %Xmlel{
            name: "participant",
            attrs: %{"xmlns" => @ns_core},
            children: [
              %Xmlel{name: "nick", children: [participant.nick]},
              %Xmlel{name: "jid", children: [participant.jid]}
            ]
          }
        ]
      }
    end
  end

  def render(channel, @ns_allowed, opts) do
    only_jids = opts[:only_jids]

    for jid <- Channel.get_allowed(channel), is_nil(only_jids) or jid in only_jids do
      Xmlel.new("item", %{"id" => jid})
    end
  end

  def render(channel, @ns_banned, opts) do
    only_jids = opts[:only_jids]

    for jid <- Channel.get_banned(channel), is_nil(only_jids) or jid in only_jids do
      Xmlel.new("item", %{"id" => jid})
    end
  end

  def get_values(values) do
    Enum.map(values, fn %Xmlel{name: "value", children: [value]} -> value end)
  end

  def get_value(%Xmlel{children: [value]}), do: value

  def process_info(%Xmlel{
        name: "publish",
        attrs: %{"node" => @ns_info},
        children: [
          %Xmlel{name: "item", children: [%Xmlel{name: "x", children: fields}]}
        ]
      }) do
    fields =
      fields
      |> Enum.map(fn %Xmlel{name: "field", attrs: %{"var" => varname}, children: [value]} ->
        {String.downcase(varname), get_value(value)}
      end)
      |> Map.new()

    {:ok, fields}
  end

  def process_info(error) do
    {:error, {"bad-request", "en", to_string(error)}}
  end

  def process_config(%Xmlel{
        name: "publish",
        attrs: %{"node" => @ns_config},
        children: [
          %Xmlel{name: "item", children: [%Xmlel{name: "x", children: fields}]}
        ]
      }) do
    fields =
      fields
      |> Enum.map(fn %Xmlel{name: "field", attrs: %{"var" => varname}, children: values} ->
        {String.downcase(varname), Enum.map(get_values(values), &String.downcase/1)}
      end)
      |> Map.new()

    {:ok, fields}
  end

  def process_config(error) do
    {:error, {"bad-request", "en", to_string(error)}}
  end

  def process_participants(%Xmlel{
        name: action,
        attrs: %{"node" => node},
        children: items
      })
      when action in ["publish", "retract"] and node in [@ns_allowed, @ns_banned] do
    jids = for %Xmlel{name: "item", attrs: %{"id" => jid}} <- items, do: jid
    {:ok, %{"action" => action, "node" => node, "jids" => jids}}
  end

  def wrapper(:result_get, node, items) do
    Xmlel.new("pubsub", %{"xmlns" => @ns_pubsub}, [
      Xmlel.new(
        "items",
        case node do
          "urn:xmpp:mix:nodes:config" ->
            %{"xmlns" => "urn:xmpp:mix:admin:0", "node" => node}

          _ ->
            %{"node" => node}
        end,
        items
      )
    ])
  end

  def wrapper(:result_set, node, _items) when node in [@ns_allowed, @ns_banned] do
    Xmlel.new("pubsub", %{"xmlns" => @ns_pubsub})
  end

  def wrapper(:result_set, node, items) do
    Xmlel.new("pubsub", %{"xmlns" => @ns_pubsub}, [
      Xmlel.new(
        "publish",
        %{"node" => node},
        case node do
          @ns_info ->
            for %Xmlel{name: "item", attrs: %{"id" => id}} <- items do
              Xmlel.new("item", %{"id" => id, "xmlns" => @ns_core})
            end

          @ns_config ->
            for %Xmlel{name: "item", attrs: %{"id" => id}} <- items do
              Xmlel.new("item", %{"id" => id, "xmlns" => @ns_admin})
            end
        end
      )
    ])
  end

  def wrapper(:event, node, items) do
    Xmlel.new("event", %{"xmlns" => @ns_event}, [
      Xmlel.new(
        "items",
        case node do
          "urn:xmpp:mix:nodes:config" ->
            %{"xmlns" => "urn:xmpp:mix:admin:0", "node" => node}

          _ ->
            %{"node" => node}
        end,
        items
      )
    ])
  end
end
