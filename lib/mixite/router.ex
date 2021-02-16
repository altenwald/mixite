defmodule Mixite.Router do
  use Exampple.Router

  discovery do
    identity(category: "conference", type: "mix", name: "mixite")

    if Application.get_env(:mixite, :create_channel, true) do
      feature("urn:xmpp:mix:core:1#create-channel")
    end

    if Application.get_env(:mixite, :searchable, true) do
      feature("urn:xmpp:mix:core:1#searchable")
    end
  end

  iq "http://jabber.org/protocol" do
    join_with("/")
    get("disco#items", Mixite.Xmpp.DiscoveryController, :items)
    get("disco#info", Mixite.Xmpp.DiscoveryController, :info)
    get("pubsub", Mixite.Xmpp.PubsubController, :get)
    set("pubsub", Mixite.Xmpp.PubsubController, :set)
  end

  iq "urn:xmpp:mix:core" do
    set("1", Mixite.Xmpp.CoreController, :core)
  end

  message do
    groupchat(Mixite.Xmpp.MessageController, :broadcast)
  end

  fallback(Mixite.Xmpp.ErrorController, :handle_error)
end
