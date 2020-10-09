defmodule Mixite.Xmpp.CoreControllerTest do
  use Exampple.Router.ConnCase

  import Exampple.Xml.Xmlel, only: [sigil_x: 2]

  describe "update-subscription" do
    test "correctly" do
      component_received ~x[
        <iq type='set'
            to='6535bb5c-732f-4a3b-8329-3923aec636a5@mix.example.com'
            from='8852aa0b-b9bd-4427-aa30-9b9b4f1b0ea9@example.com/hectic'
            id='44'>
          <update-subscription xmlns='urn:xmpp:mix:core:1'>
            <subscribe node='urn:xmpp:mix:nodes:messages'/>
            <unsubscribe node='urn:xmpp:mix:nodes:presence'/>
            <subscribe node='urn:xmpp:mix:nodes:participants'/>
            <unsubscribe node='urn:xmpp:mix:nodes:info'/>
          </update-subscription>
        </iq>
      ]

      assert_stanza_receive ~x[
        <iq type='result'
            from='6535bb5c-732f-4a3b-8329-3923aec636a5@mix.example.com'
            to='8852aa0b-b9bd-4427-aa30-9b9b4f1b0ea9@example.com/hectic'
            id='44'>
          <update-subscription xmlns='urn:xmpp:mix:core:1'
                jid='8852aa0b-b9bd-4427-aa30-9b9b4f1b0ea9@example.com'>
            <unsubscribe node='urn:xmpp:mix:nodes:presence'/>
          </update-subscription>
        </iq>
      ]
    end
  end

  describe "join" do
    test "correctly" do
      component_received ~x[
        <iq type='set'
            to='6535bb5c-732f-4a3b-8329-3923aec636a5@mix.example.com'
            from='7b62547e-704c-4961-8e21-9248e12c427d@example.com/hectic'
            id='44'>
          <join xmlns='urn:xmpp:mix:core:1'>
            <subscribe node='urn:xmpp:mix:nodes:messages'/>
            <subscribe node='urn:xmpp:mix:nodes:presence'/>
            <subscribe node='urn:xmpp:mix:nodes:participants'/>
            <subscribe node='urn:xmpp:mix:nodes:info'/>
            <nick>third witch</nick>
          </join>
        </iq>
      ]

      assert_stanza_receive ~x[
        <iq type='result'
            from='6535bb5c-732f-4a3b-8329-3923aec636a5@mix.example.com'
            to='7b62547e-704c-4961-8e21-9248e12c427d@example.com/hectic'
            id='44'>
          <join xmlns='urn:xmpp:mix:core:1'
                id='92cd9729-7755-4d41-a09b-7105c005aae2'>
            <subscribe node='urn:xmpp:mix:nodes:messages'/>
            <subscribe node='urn:xmpp:mix:nodes:participants'/>
            <subscribe node='urn:xmpp:mix:nodes:presence'/>
            <nick>third witch</nick>
          </join>
        </iq>
      ]

      to_jids = [
        "7b62547e-704c-4961-8e21-9248e12c427d@example.com",
        "8852aa0b-b9bd-4427-aa30-9b9b4f1b0ea9@example.com",
        "c97de5c2-76ed-448d-bff9-ac4f9f32a327@example.com"
      ]

      stanzas = for to_jid <- to_jids do
        ~x[
          <message from="6535bb5c-732f-4a3b-8329-3923aec636a5@mix.example.com"
                  id="uuid"
                  to="#{ to_jid }">
            <event xmlns="http://jabber.org/protocol/pubsub#event">
              <items node="urn:xmpp:mix:nodes:participants">
                <item id="92cd9729-7755-4d41-a09b-7105c005aae2">
                  <participant xmlns="urn:xmpp:mix:core:1">
                    <jid>7b62547e-704c-4961-8e21-9248e12c427d@example.com</jid>
                    <nick>third witch</nick>
                  </participant>
                </item>
              </items>
            </event>
          </message>
        ]
      end

      assert_all_stanza_receive stanzas
    end
  end
end
