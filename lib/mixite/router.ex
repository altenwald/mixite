defmodule Mixite.Router do
  use Exampple.Router

  discovery do
    identity category: "conference", type: "mix", name: "mixite"

    if Application.get_env(:mixite, :create_channel, true) do
      feature "urn:xmpp:mix:core:1#create-channel"
    end
  end

  iq "http://jabber.org/protocol" do
    join_with "/"
    get "disco#items", Mixite.Xmpp.DiscoveryController, :items
    get "disco#info", Mixite.Xmpp.DiscoveryController, :info
    get "pubsub", Mixite.Xmpp.PubsubController, :get
  end

  iq "urn:xmpp:mix:core" do
    set "1", Mixite.Xmpp.CoreController, :core
  end

  message do
    groupchat Mixite.Xmpp.MessageController, :broadcast
  end

  fallback Mixite.Xmpp.ErrorController, :error
end
