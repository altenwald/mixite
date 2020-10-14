defmodule Mixite.Xmpp.MessageController do
  use Exampple.Component

  import Mixite.Xmpp.ErrorController, only: [
    send_not_found: 1,
    send_forbidden: 1,
    send_feature_not_implemented: 2
  ]

  alias Exampple.Router.Conn
  alias Exampple.Xml.Xmlel
  alias Exampple.Xmpp.{Jid, Stanza}
  alias Mixite.{Channel, EventManager, Participant}

  def broadcast(%Conn{to_jid: %Jid{node: ""}} = conn, _query) do
    send_feature_not_implemented(conn, "groupchat messages require a channel")
  end

  def broadcast(%Conn{to_jid: %Jid{node: channel_id}} = conn, query) do
    if channel = Channel.get(channel_id) do
      user_jid = to_string(Jid.to_bare(conn.from_jid))
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
        sid = Channel.store_message(channel, payload)
        sid_tag = %Xmlel{
          name: "stanza-id",
          attrs: %{
            "xmlns" => "urn:xmpp:sid:0",
            "id" => sid,
            "by" => user_jid
          }
        }
        from_jid = to_string(Jid.to_bare(conn.to_jid))
        payload = payload ++ [sid_tag]
        EventManager.notify({:broadcast, from_jid, channel, payload})

        message_id = Channel.gen_uuid()
        channel.participants
        |> Enum.each(fn %Participant{jid: jid} ->
          payload
          |> Stanza.message(from_jid, message_id, jid)
          |> send()
        end)
      else
        send_forbidden(conn)
      end
    else
      send_not_found(conn)
    end
  end
end
