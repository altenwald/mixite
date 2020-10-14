defmodule Mixite.Xmpp.CoreControllerTest do
  use Exampple.Router.ConnCase

  import Exampple.Xml.Xmlel, only: [sigil_x: 2]

  describe "destroy channel" do
    test "correctly" do
      component_received ~x[
        <iq type='set'
            to='mix.example.com'
            from='4b2f6c32-fa80-4d97-aeec-db8e043507fe@example.com/hectic'
            id='77'>
          <destroy channel='be89d464-87d1-4351-bdff-a2cdd7bdb975' xmlns='urn:xmpp:mix:core:1'/>
        </iq>
      ]

      assert_stanza_receive ~x[
        <iq type='result'
            from='mix.example.com'
            to='4b2f6c32-fa80-4d97-aeec-db8e043507fe@example.com/hectic'
            id='77'>
          <destroy channel='be89d464-87d1-4351-bdff-a2cdd7bdb975' xmlns='urn:xmpp:mix:core:1'/>
        </iq>
      ]
    end
  end

  describe "create" do
    test "named channel correctly" do
      component_received ~x[
        <iq type='set'
            to='mix.example.com'
            from='7d4bac95-85b0-426b-9a06-d120be45b723@example.com/hectic'
            id='90'>
          <create channel='fa7c9b6a-d5c2-45cb-b807-258116df6548' xmlns='urn:xmpp:mix:core:1'/>
        </iq>
      ]

      assert_stanza_receive ~x[
        <iq type='result'
            from='mix.example.com'
            to='7d4bac95-85b0-426b-9a06-d120be45b723@example.com/hectic'
            id='90'>
          <create channel='fa7c9b6a-d5c2-45cb-b807-258116df6548' xmlns='urn:xmpp:mix:core:1'/>
        </iq>
      ]
    end

    test "ad-hoc channel correctly" do
      component_received ~x[
        <iq type='set'
            to='mix.example.com'
            from='7d4bac95-85b0-426b-9a06-d120be45b723@example.com/hectic'
            id='90'>
          <create xmlns='urn:xmpp:mix:core:1'/>
        </iq>
      ]

      assert_stanza_receive ~x[
        <iq type='result'
            from='mix.example.com'
            to='7d4bac95-85b0-426b-9a06-d120be45b723@example.com/hectic'
            id='90'>
          <create channel='uuid' xmlns='urn:xmpp:mix:core:1'/>
        </iq>
      ]
    end
  end

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

  describe "set nick" do
    test "correctly" do
      component_received ~x[
        <iq type='set'
            to='6535bb5c-732f-4a3b-8329-3923aec636a5@mix.example.com'
            from='8852aa0b-b9bd-4427-aa30-9b9b4f1b0ea9@example.com/hectic'
            id='60'>
          <setnick xmlns='urn:xmpp:mix:core:1'>
            <nick>ENIAC</nick>
          </setnick>
        </iq>
      ]

      assert_stanza_receive ~x[
        <iq type='result'
            from='6535bb5c-732f-4a3b-8329-3923aec636a5@mix.example.com'
            to='8852aa0b-b9bd-4427-aa30-9b9b4f1b0ea9@example.com/hectic'
            id='60'>
          <setnick xmlns='urn:xmpp:mix:core:1'>
            <nick>ENIAC</nick>
          </setnick>
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

  describe "leave" do
    test "correctly" do
      component_received ~x[
        <iq type='set'
            to='c5f74c1b-11e6-4a81-ab6a-afc598180b5a@mix.example.com'
            from='e784345c-4bed-4ce0-9610-e6f57b9ac6f2@example.com/hectic'
            id='50'>
          <leave xmlns='urn:xmpp:mix:core:1'/>
        </iq>
      ]

      assert_stanza_receive ~x[
        <iq type='result'
            from='c5f74c1b-11e6-4a81-ab6a-afc598180b5a@mix.example.com'
            to='e784345c-4bed-4ce0-9610-e6f57b9ac6f2@example.com/hectic'
            id='50'>
          <leave xmlns='urn:xmpp:mix:core:1'/>
        </iq>
      ]

      to_jids = [
        "2f540478-fe93-469c-8b9c-7e4ad8fd4339@example.com",
        "f8e744de-3d1b-4528-9cfd-3fa111f7f626@example.com"
      ]

      stanzas = for to_jid <- to_jids do
        ~x[
          <message from="c5f74c1b-11e6-4a81-ab6a-afc598180b5a@mix.example.com"
                  id="uuid"
                  to="#{ to_jid }">
            <event xmlns="http://jabber.org/protocol/pubsub#event">
              <items node="urn:xmpp:mix:nodes:participants">
                <retract id="3cb92e3e-798b-49c6-a157-2122356e4cea">
                  <jid>e784345c-4bed-4ce0-9610-e6f57b9ac6f2@example.com</jid>
                </retract>
              </items>
            </event>
          </message>
        ]
      end

      assert_all_stanza_receive stanzas
    end
  end
end
