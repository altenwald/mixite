defmodule Mixite.Namespaces do
  defmacro __using__(_params) do
    quote do
      @ns_xdata "jabber:x:data"

      @ns_pubsub "http://jabber.org/protocol/pubsub"
      @ns_event "http://jabber.org/protocol/pubsub#event"

      @ns_admin "urn:xmpp:mix:admin:0"
      @ns_core "urn:xmpp:mix:core:1"

      @ns_config "urn:xmpp:mix:nodes:config"
      @ns_messages "urn:xmpp:mix:nodes:messages"
      @ns_presence "urn:xmpp:mix:nodes:presence"
      @ns_info "urn:xmpp:mix:nodes:info"
      @ns_participants "urn:xmpp:mix:nodes:participants"
      @ns_allowed "urn:xmpp:mix:nodes:allowed"
      @ns_banned "urn:xmpp:mix:nodes:banned"
      @ns_avatar_metadata "urn:xmpp:avatar:metadata"
      @ns_avatar_data "urn:xmpp:avatar:data"

      def ns_to_node(@ns_config), do: "config"
      def ns_to_node(@ns_messages), do: "messages"
      def ns_to_node(@ns_presence), do: "presence"
      def ns_to_node(@ns_info), do: "information"
      def ns_to_node(@ns_participants), do: "participants"
      def ns_to_node(@ns_allowed), do: "allowed"
      def ns_to_node(@ns_banned), do: "banned"
      def ns_to_node(@ns_avatar_metadata), do: "avatar"
      def ns_to_node(@ns_avatar_data), do: "avatar"

      def node_to_ns("config"), do: [@ns_config]
      def node_to_ns("messages"), do: [@ns_messages]
      def node_to_ns("presence"), do: [@ns_presence]
      def node_to_ns("information"), do: [@ns_info]
      def node_to_ns("participants"), do: [@ns_participants]
      def node_to_ns("allowed"), do: [@ns_allowed]
      def node_to_ns("banned"), do: [@ns_banned]
      def node_to_ns("avatar"), do: [@ns_avatar_metadata, @ns_avatar_data]

      def valid_nodes() do
        ~w[ config messages presence information participants allowed banned avatar ]
      end

      def valid_ns() do
        [ @ns_config, @ns_messages, @ns_presence, @ns_info, @ns_participants, @ns_allowed, @ns_banned, @ns_avatar_metadata, @ns_avatar_data ]
      end
    end
  end
end
