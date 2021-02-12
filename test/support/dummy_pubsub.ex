defmodule Mixite.DummyPubsub do
  use Mixite.Pubsub

  alias Exampple.Xml.Xmlel

  @impl Pubsub
  def process_get_node(_channel_id, _user_jid, "urn:xmpp:mixite:0") do
    {:ok, %Xmlel{name: "mixite", children: ["Hello world!"]}}
  end

  def process_get_node(_channel_id, _user_jid, "urn:xmpp:mixite:1") do
    {:ok, [
      %Xmlel{name: "mixite", children: ["Hello world!"]},
      %Xmlel{name: "mixite", children: ["Hola mundo!"]},
      %Xmlel{name: "mixite", children: ["Ciao mondo!"]}
    ]}
  end

  def process_get_node(_channel_id, _user_jid, "urn:xmpp:mixite:error:0") do
    {:error, {"feature-not-implemented", "en", "mixite error!"}}
  end

  def process_get_node(_channel_id, _user_id, _nodes) do
    :ignore
  end
end
