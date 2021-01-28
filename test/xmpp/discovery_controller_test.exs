defmodule Exampple.Xmpp.DiscoveryControllerTest do
  use Exampple.Router.ConnCase

  import Exampple.Xml.Xmlel, only: [sigil_x: 2]

  describe "discovery: " do
    test "disco#info for component" do
      user = "user-id@example.com/res"
      component_received(~x[
        <iq type='get' id='1' to='mixite.example.com' from='#{user}'>
          <query xmlns='http://jabber.org/protocol/disco#info'/>
        </iq>
      ])

      assert_stanza_receive(~x[
        <iq type='result' id='1' to='#{user}' from='mixite.example.com'>
          <query xmlns='http://jabber.org/protocol/disco#info'>
            <identity category="conference" name="mixite" type="mix"/>
            <feature var="http://jabber.org/protocol/disco#info"/>
            <feature var="http://jabber.org/protocol/disco#items"/>
            <feature var="http://jabber.org/protocol/pubsub"/>
            <feature var="urn:xmpp:mix:core:1"/>
            <feature var="urn:xmpp:mix:core:1#create-channel"/>
          </query>
        </iq>
      ])
    end

    test "disco#info from a channel" do
      user = "c3b10914-905d-4920-a5cd-146a0061e478@example.com/res"

      component_received(
        ~x[
        <iq type='get' id='1' to='be89d464-87d1-4351-bdff-a2cdd7bdb975@mixite.example.com' from='#{
          user
        }'>
          <query xmlns='http://jabber.org/protocol/disco#info'/>
        </iq>
      ]
      )

      assert_stanza_receive(~x[
        <iq type='result' id='1' to='#{user}' from='be89d464-87d1-4351-bdff-a2cdd7bdb975@mixite.example.com'>
          <query xmlns='http://jabber.org/protocol/disco#info'>
            <identity category="conference" name="pennsylvania" type="mix"/>
            <feature var='http://jabber.org/protocol/disco#info'/>
            <feature var='urn:xmpp:mix:core:1'/>
            <feature var='urn:xmpp:mam:2'/>
          </query>
        </iq>
      ])
    end

    test "disco#items general" do
      user = "8852aa0b-b9bd-4427-aa30-9b9b4f1b0ea9@example.com/res"
      component_received(~x[
        <iq type='get' id='1' to='mixite.example.com' from='#{user}'>
          <query xmlns='http://jabber.org/protocol/disco#items'/>
        </iq>
      ])

      assert_stanza_receive(~x[
        <iq type='result' id='1' to='#{user}' from='mixite.example.com'>
          <query xmlns='http://jabber.org/protocol/disco#items'>
            <item jid='28be3cc7-d605-40dd-8b5a-012b59e90c26@mixite.example.com'/>
            <item jid='3cfd82c0-8453-4198-a706-dbec5692dc43@mixite.example.com'/>
            <item jid='6535bb5c-732f-4a3b-8329-3923aec636a5@mixite.example.com'/>
          </query>
        </iq>
      ])
    end

    test "disco#items from a channel" do
      user = "c3b10914-905d-4920-a5cd-146a0061e478@example.com/res"

      component_received(
        ~x[
        <iq type='get' id='1' to='be89d464-87d1-4351-bdff-a2cdd7bdb975@mixite.example.com' from='#{
          user
        }'>
          <query xmlns='http://jabber.org/protocol/disco#items' node='mix'/>
        </iq>
      ]
      )

      assert_stanza_receive(~x[
        <iq type='result' id='1' to='#{user}' from='be89d464-87d1-4351-bdff-a2cdd7bdb975@mixite.example.com'>
          <query xmlns='http://jabber.org/protocol/disco#items' node='mix'>
            <item jid='be89d464-87d1-4351-bdff-a2cdd7bdb975@mixite.example.com'
                  node='urn:xmpp:mix:nodes:config'/>
            <item jid='be89d464-87d1-4351-bdff-a2cdd7bdb975@mixite.example.com'
                  node='urn:xmpp:mix:nodes:messages'/>
            <item jid='be89d464-87d1-4351-bdff-a2cdd7bdb975@mixite.example.com'
                  node='urn:xmpp:mix:nodes:participants'/>
            <item jid='be89d464-87d1-4351-bdff-a2cdd7bdb975@mixite.example.com'
                  node='urn:xmpp:mix:nodes:presence'/>
          </query>
        </iq>
      ])
    end

    test "disco#items from a not belonging channel" do
      user = "user-id@example.com/res"

      component_received(
        ~x[
        <iq type='get' id='1' to='be89d464-87d1-4351-bdff-a2cdd7bdb975@mixite.example.com' from='#{
          user
        }'>
          <query xmlns='http://jabber.org/protocol/disco#items' node='mix'/>
        </iq>
      ]
      )

      assert_stanza_receive(~x[
        <iq type='error' id='1' to='#{user}' from='be89d464-87d1-4351-bdff-a2cdd7bdb975@mixite.example.com'>
          <query xmlns='http://jabber.org/protocol/disco#items' node='mix'/>
          <error type='auth'>
            <forbidden xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/>
            <text lang='en' xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'>
              forbidden access to channel
            </text>
          </error>
        </iq>
      ])
    end
  end
end
