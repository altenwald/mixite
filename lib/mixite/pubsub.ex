defmodule Mixite.Pubsub do
  alias Exampple.Xml.Xmlel
  alias Mixite.Channel

  @ns_xdata "jabber:x:data"
  @ns_admin "urn:xmpp:mix:admin:0"
  @ns_core "urn:xmpp:mix:core:1"
  @ns_config "urn:xmpp:mix:nodes:config"
  @ns_info "urn:xmpp:mix:nodes:info"
  @ns_participants "urn:xmpp:mix:nodes:participants"
  @ns_allowed "urn:xmpp:mix:nodes:allowed"

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
              :ignore |
              {:error, {String.t(), String.t(), String.t()}} |
              {:ok, Xmlel.t()} |
              {:ok, [Xmlel.t()]}

  @callback process_set_node(Channel.id(), Channel.user_jid(), Channel.nodes(), Xmlel.t()) ::
              :ignore |
              {:error, {String.t(), String.t(), String.t()}} |
              {:ok, Channel.t(), Xmlel.t()} |
              {:ok, Channel.t(), [Xmlel.t()]}

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
          :ignore |
          {:error, {String.t(), String.t(), String.t()}} |
          {:ok, Xmlel.t()} |
          {:ok, [Xmlel.t()]}
  def process_get_node(id, user_jid, nodes) do
    backend().process_get_node(id, user_jid, nodes)
  end

  @spec process_set_node(Channel.id(), Channel.user_jid(), Channel.nodes(), Xmlel.t()) ::
          :ignore |
          {:error, {String.t(), String.t(), String.t()}} |
          {:ok, Channel.t(), Xmlel.t()} |
          {:ok, Channel.t(), [Xmlel.t()]}
  def process_set_node(id, user_jid, nodes, query) do
    backend().process_set_node(id, user_jid, nodes, query)
  end

  defp field(name, type \\ nil, value)
  defp field(_name, _type, nil), do: []
  defp field(_name, _type, []), do: []

  defp field(name, type, value) do
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

  def render(channel, @ns_config) do
    %Xmlel{
      name: "item",
      attrs: %{"id" => to_string(channel.updated_at)},
      children: [
        %Xmlel{
          name: "x",
          attrs: %{"xmlns" => @ns_xdata, "type" => "result"},
          children:
            field("FORM_TYPE", "hidden", @ns_admin) ++
              field("Owner", channel.owners) ++
              field("Administrator", channel.administrators) ++
              Enum.map(Channel.config_params(channel), fn
                {{key, type}, value} -> hd(field(key, type, value))
                {key, value} -> hd(field(key, value))
              end)
        }
      ]
    }
  end

  def render(channel, @ns_info) do
    %Xmlel{
      name: "item",
      attrs: %{"id" => to_string(channel.updated_at)},
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

  def render(channel, @ns_participants) do
    for participant <- channel.participants do
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

  def render(channel, @ns_allowed) do
    for participant <- channel.participants do
      %Xmlel{
        name: "item",
        attrs: %{"id" => participant.jid}
      }
    end
  end

  def get_values(values) do
    Enum.map(values, fn %Xmlel{name: "value", children: [value]} -> value end)
  end

  def get_value(%Xmlel{children: [value]}), do: value

  def process_info(%Xmlel{
           name: "items",
           children: [%Xmlel{name: "item", children: [%Xmlel{name: "x", children: fields}]}]
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

  def process_config(
         %Xmlel{
           name: "items",
           children: [%Xmlel{name: "item", children: [%Xmlel{name: "x", children: fields}]}]
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
end
