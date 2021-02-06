defmodule Mixite.Xmpp.MessageController do
  use Exampple.Component

  require Logger

  import Mixite.Xmpp.ErrorController,
    only: [
      send_not_found: 1,
      send_forbidden: 1,
      send_feature_not_implemented: 3
    ]

  alias Exampple.Router.Conn
  alias Exampple.Xml.Xmlel
  alias Exampple.Xmpp.Jid
  alias Mixite.Channel

  defp send_broadcast(conn, channel, payload) do
    from_jid = Jid.to_bare(conn.to_jid)
    Channel.send_broadcast(channel, payload, from_jid)
  end

  def broadcast(%Conn{to_jid: %Jid{node: ""}} = conn, _query) do
    send_feature_not_implemented(conn, "en", "groupchat messages require a channel")
  end

  def broadcast(%Conn{to_jid: %Jid{node: channel_id}} = conn, query) do
    if channel = Channel.get(channel_id) do
      user_jid = Jid.to_bare(conn.from_jid)

      if Channel.is_participant?(channel, user_jid) do
        participant = Channel.get_participant(channel, user_jid)

        mix_tag = %Xmlel{
          name: "mix",
          attrs: %{"xmlns" => "urn:xmpp:mix:core:1"},
          children: [
            %Xmlel{name: "nick", children: [participant.nick]},
            %Xmlel{name: "jid", children: [participant.jid]}
          ]
        }

        payload = query ++ [mix_tag]

        attrs = %{
          "from" => Jid.to_bare(conn.from_jid),
          "to" => Jid.to_bare(conn.to_jid),
          "type" => conn.type,
          "id" => conn.id
        }

        message = Xmlel.new("message", attrs, payload)

        case Channel.store_message(channel, message) do
          {:error, _} = error ->
            Logger.error("store message error: #{inspect(error)}")

            send_feature_not_implemented(
              conn,
              "en",
              "broadcast and store message is not supported"
            )

          {:ok, nil} ->
            send_broadcast(conn, channel, payload)

          {:ok, sid} when is_binary(sid) ->
            sid_tag = %Xmlel{
              name: "stanza-id",
              attrs: %{
                "xmlns" => "urn:xmpp:sid:0",
                "id" => sid,
                "by" => user_jid
              }
            }

            payload = payload ++ [sid_tag]
            send_broadcast(conn, channel, payload)
        end
      else
        send_forbidden(conn)
      end
    else
      send_not_found(conn)
    end
  end
end
