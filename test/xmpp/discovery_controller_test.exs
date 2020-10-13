defmodule Exampple.Xmpp.DiscoveryControllerTest do
  use Exampple.Router.ConnCase

  import Exampple.Xml.Xmlel, only: [sigil_x: 2]

  @user "user-id@example.com/res"

  describe "discovery: " do
    test "disco#info for component" do
      component_received ~x[
        <iq type='get' id='1' to='mixite.example.com' from='#{@user}'>
          <query xmlns='http://jabber.org/protocol/disco#info'/>
        </iq>
      ]

      assert_stanza_receive ~x[
        <iq type='result' id='1' to='#{@user}' from='mixite.example.com'>
          <query xmlns='http://jabber.org/protocol/disco#info'>
            <identity category="conference" name="mixite" type="mix"/>
            <feature var="http://jabber.org/protocol/disco#info"/>
            <feature var="http://jabber.org/protocol/disco#items"/>
            <feature var="http://jabber.org/protocol/pubsub"/>
            <feature var="urn:xmpp:mix:core:1"/>
            <feature var="urn:xmpp:mix:core:1#create-channel"/>
          </query>
        </iq>
      ]
    end

    test "disco#info from a channel" do
      component_received ~x[
        <iq type='get' id='1' to='be89d464-87d1-4351-bdff-a2cdd7bdb975@mixite.example.com' from='#{@user}'>
          <query xmlns='http://jabber.org/protocol/disco#info'/>
        </iq>
      ]

      assert_stanza_receive ~x[
        <iq type='result' id='1' to='#{@user}' from='be89d464-87d1-4351-bdff-a2cdd7bdb975@mixite.example.com'>
          <query xmlns='http://jabber.org/protocol/disco#info'>
            <identity category="conference" name="pennsylvania" type="mix"/>
            <feature var='http://jabber.org/protocol/disco#info'/>
            <feature var='urn:xmpp:mix:core:1'/>
            <feature var='urn:xmpp:mam:2'/>
          </query>
        </iq>
      ]
    end

    test "disco#items from a channel" do
      component_received ~x[
        <iq type='get' id='1' to='be89d464-87d1-4351-bdff-a2cdd7bdb975@mixite.example.com' from='#{@user}'>
          <query xmlns='http://jabber.org/protocol/disco#items' node='mix'/>
        </iq>
      ]

      assert_stanza_receive ~x[
        <iq type='result' id='1' to='#{@user}' from='be89d464-87d1-4351-bdff-a2cdd7bdb975@mixite.example.com'>
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
      ]
    end
  end
end
