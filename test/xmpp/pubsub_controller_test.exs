defmodule Mixite.Xmpp.PubsubControllerTest do
  use Exampple.Router.ConnCase

  import Exampple.Xml.Xmlel, only: [sigil_x: 2]

  describe "pubsub: " do
    test "nodes:info from a channel" do
      component_received ~x[
        <iq from='user-id@example.com/UUID-c8y/1573'
            id='kl2fax27'
            to='be89d464-87d1-4351-bdff-a2cdd7bdb975@mixite.example.com'
            type='get'>
          <pubsub xmlns='http://jabber.org/protocol/pubsub'>
            <items node='urn:xmpp:mix:nodes:info'/>
          </pubsub>
        </iq>
      ]

      assert_stanza_receive ~x[
        <iq from='be89d464-87d1-4351-bdff-a2cdd7bdb975@mixite.example.com'
            id='kl2fax27'
            to='user-id@example.com/UUID-c8y/1573'
            type='result'>
          <pubsub xmlns='http://jabber.org/protocol/pubsub'>
            <items node='urn:xmpp:mix:nodes:info'>
              <item id='2020-09-23 00:36:20.363444'>
                <x xmlns='jabber:x:data' type='result'>
                  <field var='FORM_TYPE' type='hidden'>
                    <value>urn:xmpp:mix:core:1</value>
                  </field>
                  <field var='Name'>
                    <value>pennsylvania</value>
                  </field>
                  <field var='Description'>
                    <value>Pennsylvania University</value>
                  </field>
                </x>
              </item>
            </items>
          </pubsub>
        </iq>
      ]
    end

    test "nodes:participants from a channel" do
      component_received ~x[
        <iq from='user-id@example.com/UUID-c8y/1573'
            id='kl2fax27'
            to='be89d464-87d1-4351-bdff-a2cdd7bdb975@mixite.example.com'
            type='get'>
          <pubsub xmlns='http://jabber.org/protocol/pubsub'>
            <items node='urn:xmpp:mix:nodes:participants'/>
          </pubsub>
        </iq>
      ]

      assert_stanza_receive ~x[
        <iq from='be89d464-87d1-4351-bdff-a2cdd7bdb975@mixite.example.com'
            id='kl2fax27'
            to='user-id@example.com/UUID-c8y/1573'
            type='result'>
          <pubsub xmlns='http://jabber.org/protocol/pubsub'>
            <items node='urn:xmpp:mix:nodes:participants'>
              <item id="ac3c30e4-e1d5-489f-80f4-671735f444ed">
                <participant xmlns='urn:xmpp:mix:core:1'>
                  <nick>john-eckert</nick>
                  <jid>4b2f6c32-fa80-4d97-aeec-db8e043507fe@example.com</jid>
                </participant>
              </item>
              <item id="2846ff3f-6b90-48e5-9aad-c3782393d8be">
                <participant xmlns='urn:xmpp:mix:core:1'>
                  <nick>john-mauchly</nick>
                  <jid>c3b10914-905d-4920-a5cd-146a0061e478@example.com</jid>
                </participant>
              </item>
            </items>
          </pubsub>
        </iq>
      ]
    end
  end
end
