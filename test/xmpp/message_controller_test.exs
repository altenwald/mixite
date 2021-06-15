defmodule Mixite.Xmpp.MessageControllerTest do
  use Exampple.Router.ConnCase

  import Exampple.Xml.Xmlel, only: [sigil_x: 2]

  describe "broadcast" do
    test "incorrectly to the component (no channel)" do
      component_received(~x[
        <message type='groupchat'
            to='mix.example.com'
            from='2f540478-fe93-469c-8b9c-7e4ad8fd4339@example.com/hectic'
            id='80'>
          <body>Hello world!</body>
        </message>
      ])

      assert_stanza_receive(~x[
        <message to="2f540478-fe93-469c-8b9c-7e4ad8fd4339@example.com/hectic"
                 id="80"
                 from="mix.example.com"
                 type="error">
          <body>Hello world!</body>
          <error type="cancel">
            <feature-not-implemented xmlns="urn:ietf:params:xml:ns:xmpp-stanzas"/>
            <text lang="en" xmlns="urn:ietf:params:xml:ns:xmpp-stanzas">
              groupchat messages require a channel
            </text>
          </error>
        </message>
      ])

      refute_receive _, 200
    end

    test "incorrectly to a non-existent channel" do
      component_received(~x[
        <message type='groupchat'
            to='non-existent-channel@mix.example.com'
            from='2f540478-fe93-469c-8b9c-7e4ad8fd4339@example.com/hectic'
            id='80'>
          <body>Hello world!</body>
        </message>
      ])

      assert_stanza_receive(~x[
        <message to="2f540478-fe93-469c-8b9c-7e4ad8fd4339@example.com/hectic"
                 id="80"
                 from="non-existent-channel@mix.example.com"
                 type="error">
          <body>Hello world!</body>
          <error type='cancel'>
            <item-not-found xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/>
            <text lang='en' xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'>
              channel not found
            </text>
          </error>
        </message>
      ])

      refute_receive _, 200
    end

    test "incorrectly to a non-belonging channel" do
      component_received(~x[
        <message type='groupchat'
            to='c5f74c1b-11e6-4a81-ab6a-afc598180b5a@mix.example.com'
            from='user-id@example.com/hectic'
            id='80'>
          <body>Hello world!</body>
        </message>
      ])

      assert_stanza_receive(~x[
        <message to="user-id@example.com/hectic"
                 id="80"
                 from="c5f74c1b-11e6-4a81-ab6a-afc598180b5a@mix.example.com"
                 type="error">
          <body>Hello world!</body>
          <error type='auth'>
            <forbidden xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/>
            <text lang='en' xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'>
              forbidden access to channel
            </text>
          </error>
        </message>
      ])

      refute_receive _, 200
    end

    test "incorrectly storage buggy" do
      component_received(~x[
        <message type='groupchat'
            to='c5f74c1b-11e6-4a81-ab6a-afc598180b5a@mix.example.com'
            from='2f540478-fe93-469c-8b9c-7e4ad8fd4339@example.com/hectic'
            id='error'>
          <body>Hello world!</body>
        </message>
      ])

      assert_stanza_receive(~x[
        <message to="2f540478-fe93-469c-8b9c-7e4ad8fd4339@example.com/hectic"
                 id="error"
                 from="c5f74c1b-11e6-4a81-ab6a-afc598180b5a@mix.example.com"
                 type="error">
          <body>Hello world!</body>
          <error type='cancel'>
            <feature-not-implemented xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/>
            <text lang='en' xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'>
              broadcast and store message is not supported
            </text>
          </error>
        </message>
      ])

      refute_receive _, 200
    end

    test "correctly" do
      component_received(~x[
        <message type='groupchat'
            to='c5f74c1b-11e6-4a81-ab6a-afc598180b5a@mix.example.com'
            from='2f540478-fe93-469c-8b9c-7e4ad8fd4339@example.com/hectic'
            id='80'>
          <body>Hello world!</body>
        </message>
      ])

      to_jids = [
        "2f540478-fe93-469c-8b9c-7e4ad8fd4339@example.com",
        "f8e744de-3d1b-4528-9cfd-3fa111f7f626@example.com",
        "e784345c-4bed-4ce0-9610-e6f57b9ac6f2@example.com"
      ]

      stanzas =
        for to_jid <- to_jids do
          ~x[
          <message from="c5f74c1b-11e6-4a81-ab6a-afc598180b5a@mix.example.com"
                   id="80"
                   to="#{to_jid}"
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

      assert_all_stanza_receive(stanzas)

      refute_receive _, 200
    end

    test "correctly without storage" do
      component_received(~x[
        <message type='groupchat'
            to='c5f74c1b-11e6-4a81-ab6a-afc598180b5a@mix.example.com'
            from='2f540478-fe93-469c-8b9c-7e4ad8fd4339@example.com/hectic'
            id='disable-store'>
          <body>Hello world!</body>
        </message>
      ])

      to_jids = [
        "2f540478-fe93-469c-8b9c-7e4ad8fd4339@example.com",
        "f8e744de-3d1b-4528-9cfd-3fa111f7f626@example.com",
        "e784345c-4bed-4ce0-9610-e6f57b9ac6f2@example.com"
      ]

      stanzas =
        for to_jid <- to_jids do
          ~x[
          <message from="c5f74c1b-11e6-4a81-ab6a-afc598180b5a@mix.example.com"
                   id="disable-store"
                   to="#{to_jid}"
                   type="groupchat">
            <body>Hello world!</body>
            <mix xmlns="urn:xmpp:mix:core:1">
              <nick>kathleen-booth</nick>
              <jid>2f540478-fe93-469c-8b9c-7e4ad8fd4339@example.com</jid>
            </mix>
          </message>
        ]
        end

      assert_all_stanza_receive(stanzas)

      refute_receive _, 200
    end

    test "correctly without type" do
      component_received(~x[
        <message
            to='c5f74c1b-11e6-4a81-ab6a-afc598180b5a@mix.example.com'
            from='2f540478-fe93-469c-8b9c-7e4ad8fd4339@example.com/hectic'
            id='disable-store'>
          <paused xmlns='http://jabber.org/protocol/chatstates'/>
        </message>
      ])

      to_jids = [
        "2f540478-fe93-469c-8b9c-7e4ad8fd4339@example.com",
        "f8e744de-3d1b-4528-9cfd-3fa111f7f626@example.com",
        "e784345c-4bed-4ce0-9610-e6f57b9ac6f2@example.com"
      ]

      stanzas =
        for to_jid <- to_jids do
          ~x[
          <message from="c5f74c1b-11e6-4a81-ab6a-afc598180b5a@mix.example.com"
                   id="disable-store"
                   to="#{to_jid}">
            <paused xmlns='http://jabber.org/protocol/chatstates'/>
            <mix xmlns="urn:xmpp:mix:core:1">
              <nick>kathleen-booth</nick>
              <jid>2f540478-fe93-469c-8b9c-7e4ad8fd4339@example.com</jid>
            </mix>
          </message>
        ]
        end

      assert_all_stanza_receive(stanzas)

      refute_receive _, 200
    end

    test "correctly with more complete payload" do
      component_received(~x[
        <message type='groupchat'
            to='c5f74c1b-11e6-4a81-ab6a-afc598180b5a@mix.example.com'
            from='2f540478-fe93-469c-8b9c-7e4ad8fd4339@example.com/hectic'
            id='80'>
          <body>Hello world!</body>
          <markable xmlns='urn:xmpp:chat-markers:0'/>
          <store xmlns='urn:xmpp:hints'/>
        </message>
      ])

      to_jids = [
        "2f540478-fe93-469c-8b9c-7e4ad8fd4339@example.com",
        "f8e744de-3d1b-4528-9cfd-3fa111f7f626@example.com",
        "e784345c-4bed-4ce0-9610-e6f57b9ac6f2@example.com"
      ]

      stanzas =
        for to_jid <- to_jids do
          ~x[
          <message from="c5f74c1b-11e6-4a81-ab6a-afc598180b5a@mix.example.com"
                   id="80"
                   to="#{to_jid}"
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

      assert_all_stanza_receive(stanzas)

      refute_receive _, 200
    end
  end
end
