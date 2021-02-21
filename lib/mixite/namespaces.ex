defmodule Mixite.Namespaces do
  defmacro __using__(_params) do
    quote do
      @ns_xdata "jabber:x:data"

      @ns_pubsub "http://jabber.org/protocol/pubsub"
      @ns_event "http://jabber.org/protocol/pubsub#event"

      @ns_admin "urn:xmpp:mix:admin:0"
      @ns_core "urn:xmpp:mix:core:1"

      @ns_config "urn:xmpp:mix:nodes:config"
      @ns_info "urn:xmpp:mix:nodes:info"
      @ns_participants "urn:xmpp:mix:nodes:participants"
      @ns_allowed "urn:xmpp:mix:nodes:allowed"
      @ns_banned "urn:xmpp:mix:nodes:banned"
      @ns_avatar "urn:xmpp:mix:nodes:avatar"
    end
  end
end
