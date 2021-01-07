defmodule Mixite.Xmpp.MessageControllerTest do
  use Exampple.Router.ConnCase

  import Exampple.Xml.Xmlel, only: [sigil_x: 2]

  describe "broadcast" do
    test "correctly" do
      component_received ~x[
        <message type='groupchat'
            to='c5f74c1b-11e6-4a81-ab6a-afc598180b5a@mix.example.com'
            from='2f540478-fe93-469c-8b9c-7e4ad8fd4339@example.com/hectic'
            id='80'>
          <body>Hello world!</body>
        </message>
      ]

      to_jids = [
        "2f540478-fe93-469c-8b9c-7e4ad8fd4339@example.com",
        "f8e744de-3d1b-4528-9cfd-3fa111f7f626@example.com",
        "e784345c-4bed-4ce0-9610-e6f57b9ac6f2@example.com"
      ]

      stanzas = for to_jid <- to_jids do
        ~x[
          <message from="c5f74c1b-11e6-4a81-ab6a-afc598180b5a@mix.example.com"
                   id="uuid"
                   to="#{ to_jid }"
                   type="groupchat">
            <body>Hello world!</body>
            <mix xmlns="urn:xmpp:mix:core:1">
              <nick>kathleen-booth</nick>
              <jid>2f540478-fe93-469c-8b9c-7e4ad8fd4339@example.com</jid>
            </mix>
            <stanza-id by="2f540478-fe93-469c-8b9c-7e4ad8fd4339@example.com"
                       id="6c015cac-ca8e-44d1-9b6d-b719f76edfaf"
                       xmlns="urn:xmpp:sid:0"/>
          </message>
        ]
      end

      assert_all_stanza_receive stanzas
    end

    test "correctly without storage" do
      component_received ~x[
        <message type='groupchat'
            to='c5f74c1b-11e6-4a81-ab6a-afc598180b5a@mix.example.com'
            from='2f540478-fe93-469c-8b9c-7e4ad8fd4339@example.com/hectic'
            id='disable-store'>
          <body>Hello world!</body>
        </message>
      ]

      to_jids = [
        "2f540478-fe93-469c-8b9c-7e4ad8fd4339@example.com",
        "f8e744de-3d1b-4528-9cfd-3fa111f7f626@example.com",
        "e784345c-4bed-4ce0-9610-e6f57b9ac6f2@example.com"
      ]

      stanzas = for to_jid <- to_jids do
        ~x[
          <message from="c5f74c1b-11e6-4a81-ab6a-afc598180b5a@mix.example.com"
                   id="uuid"
                   to="#{ to_jid }"
                   type="groupchat">
            <body>Hello world!</body>
            <mix xmlns="urn:xmpp:mix:core:1">
              <nick>kathleen-booth</nick>
              <jid>2f540478-fe93-469c-8b9c-7e4ad8fd4339@example.com</jid>
            </mix>
          </message>
        ]
      end

      assert_all_stanza_receive stanzas
    end

    test "correctly with more complete payload" do
      component_received ~x[
        <message type='groupchat'
            to='c5f74c1b-11e6-4a81-ab6a-afc598180b5a@mix.example.com'
            from='2f540478-fe93-469c-8b9c-7e4ad8fd4339@example.com/hectic'
            id='80'>
          <body>Hello world!</body>
          <markable xmlns='urn:xmpp:chat-markers:0'/>
          <store xmlns='urn:xmpp:hints'/>
        </message>
      ]

      to_jids = [
        "2f540478-fe93-469c-8b9c-7e4ad8fd4339@example.com",
        "f8e744de-3d1b-4528-9cfd-3fa111f7f626@example.com",
        "e784345c-4bed-4ce0-9610-e6f57b9ac6f2@example.com"
      ]

      stanzas = for to_jid <- to_jids do
        ~x[
          <message from="c5f74c1b-11e6-4a81-ab6a-afc598180b5a@mix.example.com"
                   id="uuid"
                   to="#{ to_jid }"
                   type="groupchat">
            <body>Hello world!</body>
            <markable xmlns='urn:xmpp:chat-markers:0'/>
            <store xmlns='urn:xmpp:hints'/>
            <mix xmlns="urn:xmpp:mix:core:1">
              <nick>kathleen-booth</nick>
              <jid>2f540478-fe93-469c-8b9c-7e4ad8fd4339@example.com</jid>
            </mix>
            <stanza-id by="2f540478-fe93-469c-8b9c-7e4ad8fd4339@example.com"
                       id="6c015cac-ca8e-44d1-9b6d-b719f76edfaf"
                       xmlns="urn:xmpp:sid:0"/>
          </message>
        ]
      end

      assert_all_stanza_receive stanzas
    end
  end
end
