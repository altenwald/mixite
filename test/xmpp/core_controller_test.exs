defmodule Mixite.Xmpp.CoreControllerTest do
  use Exampple.Router.ConnCase

  import Exampple.Xml.Xmlel, only: [sigil_x: 2]

  describe "destroy channel" do
    test "correctly" do
      component_received(~x[
        <iq type='set'
            to='mix.example.com'
            from='4b2f6c32-fa80-4d97-aeec-db8e043507fe@example.com/hectic'
            id='77'>
          <destroy channel='be89d464-87d1-4351-bdff-a2cdd7bdb975' xmlns='urn:xmpp:mix:core:1'/>
        </iq>
      ])

      assert_stanza_receive(~x[
        <iq type='result'
            from='mix.example.com'
            to='4b2f6c32-fa80-4d97-aeec-db8e043507fe@example.com/hectic'
            id='77'>
          <destroy channel='be89d464-87d1-4351-bdff-a2cdd7bdb975' xmlns='urn:xmpp:mix:core:1'/>
        </iq>
      ])

      refute_receive _, 200
    end

    test "not found" do
      component_received(~x[
        <iq type='set'
            to='mix.example.com'
            from='4b2f6c32-fa80-4d97-aeec-db8e043507fe@example.com/hectic'
            id='77'>
          <destroy channel='inexistent-channel' xmlns='urn:xmpp:mix:core:1'/>
        </iq>
      ])

      assert_stanza_receive(~x[
        <iq type='error'
            from='mix.example.com'
            to='4b2f6c32-fa80-4d97-aeec-db8e043507fe@example.com/hectic'
            id='77'>
          <destroy channel='inexistent-channel' xmlns='urn:xmpp:mix:core:1'/>
          <error type='cancel'>
            <item-not-found xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/>
            <text lang='en' xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'>
              channel not found
            </text>
          </error>
        </iq>
      ])

      refute_receive _, 200
    end

    test "forbidden" do
      component_received(~x[
        <iq type='set'
            to='mix.example.com'
            from='user-id@example.com/hectic'
            id='77'>
          <destroy channel='be89d464-87d1-4351-bdff-a2cdd7bdb975' xmlns='urn:xmpp:mix:core:1'/>
        </iq>
      ])

      assert_stanza_receive(~x[
        <iq type='error'
            from='mix.example.com'
            to='user-id@example.com/hectic'
            id='77'>
          <destroy channel='be89d464-87d1-4351-bdff-a2cdd7bdb975' xmlns='urn:xmpp:mix:core:1'/>
          <error type='auth'>
            <forbidden xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/>
            <text lang='en' xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'>
              forbidden access to channel
            </text>
          </error>
        </iq>
      ])

      refute_receive _, 200
    end
  end

  describe "create" do
    test "named channel correctly" do
      component_received(~x[
        <iq type='set'
            to='mix.example.com'
            from='7d4bac95-85b0-426b-9a06-d120be45b723@example.com/hectic'
            id='90'>
          <create channel='fa7c9b6a-d5c2-45cb-b807-258116df6548' xmlns='urn:xmpp:mix:core:1'/>
        </iq>
      ])

      assert_stanza_receive(~x[
        <iq type='result'
            from='mix.example.com'
            to='7d4bac95-85b0-426b-9a06-d120be45b723@example.com/hectic'
            id='90'>
          <create channel='fa7c9b6a-d5c2-45cb-b807-258116df6548' xmlns='urn:xmpp:mix:core:1'/>
        </iq>
      ])

      refute_receive _, 200
    end

    test "named channel incorrectly" do
      component_received(~x[
        <iq type='set'
            to='mix.example.com'
            from='fail@example.com/hectic'
            id='90'>
          <create channel='fa7c9b6a-d5c2-45cb-b807-258116df6548' xmlns='urn:xmpp:mix:core:1'/>
        </iq>
      ])

      assert_stanza_receive(~x[
        <iq type='error'
            from='mix.example.com'
            to='fail@example.com/hectic'
            id='90'>
          <create channel='fa7c9b6a-d5c2-45cb-b807-258116df6548' xmlns='urn:xmpp:mix:core:1'/>
          <error type='wait'>
            <internal-server-error xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/>
            <text lang='en' xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'>
              an internal error happened
            </text>
          </error>
        </iq>
      ])

      refute_receive _, 200
    end

    test "ad-hoc channel correctly" do
      component_received(~x[
        <iq type='set'
            to='mix.example.com'
            from='7d4bac95-85b0-426b-9a06-d120be45b723@example.com/hectic'
            id='90'>
          <create xmlns='urn:xmpp:mix:core:1'/>
        </iq>
      ])

      assert_stanza_receive(~x[
        <iq type='result'
            from='mix.example.com'
            to='7d4bac95-85b0-426b-9a06-d120be45b723@example.com/hectic'
            id='90'>
          <create channel='uuid' xmlns='urn:xmpp:mix:core:1'/>
        </iq>
      ])

      refute_receive _, 200
    end
  end

  describe "update-subscription" do
    test "correctly" do
      component_received(~x[
        <iq type='set'
            to='6535bb5c-732f-4a3b-8329-3923aec636a5@mix.example.com'
            from='8852aa0b-b9bd-4427-aa30-9b9b4f1b0ea9@example.com/hectic'
            id='44'>
          <update-subscription xmlns='urn:xmpp:mix:core:1'>
            <subscribe node='urn:xmpp:mix:nodes:participants'/>
            <unsubscribe node='urn:xmpp:mix:nodes:info'/>
          </update-subscription>
        </iq>
      ])

      assert_stanza_receive(~x[
        <iq type='result'
            from='6535bb5c-732f-4a3b-8329-3923aec636a5@mix.example.com'
            to='8852aa0b-b9bd-4427-aa30-9b9b4f1b0ea9@example.com/hectic'
            id='44'>
          <update-subscription xmlns='urn:xmpp:mix:core:1'
                jid='8852aa0b-b9bd-4427-aa30-9b9b4f1b0ea9@example.com'>
            <unsubscribe node='urn:xmpp:mix:nodes:info'/>
          </update-subscription>
        </iq>
      ])

      refute_receive _, 200
    end

    test "incorrectly" do
      component_received(~x[
        <iq type='set'
            to='6535bb5c-732f-4a3b-8329-3923aec636a5@mix.example.com'
            from='c97de5c2-76ed-448d-bff9-ac4f9f32a327@example.com/hectic'
            id='44'>
          <update-subscription xmlns='urn:xmpp:mix:core:1'>
            <subscribe node='urn:xmpp:mix:nodes:messages'/>
            <unsubscribe node='urn:xmpp:mix:nodes:presence'/>
            <subscribe node='urn:xmpp:mix:nodes:participants'/>
            <unsubscribe node='urn:xmpp:mix:nodes:info'/>
          </update-subscription>
        </iq>
      ])

      assert_stanza_receive(~x[
        <iq type='error'
            from='6535bb5c-732f-4a3b-8329-3923aec636a5@mix.example.com'
            to='c97de5c2-76ed-448d-bff9-ac4f9f32a327@example.com/hectic'
            id='44'>
          <update-subscription xmlns='urn:xmpp:mix:core:1'>
            <subscribe node='urn:xmpp:mix:nodes:messages'/>
            <unsubscribe node='urn:xmpp:mix:nodes:presence'/>
            <subscribe node='urn:xmpp:mix:nodes:participants'/>
            <unsubscribe node='urn:xmpp:mix:nodes:info'/>
          </update-subscription>
          <error type='wait'>
            <internal-server-error xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/>
            <text lang='en' xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'>
              an internal error happened
            </text>
          </error>
        </iq>
      ])

      refute_receive _, 200
    end

    test "incorrectly (forbidden)" do
      component_received(~x[
        <iq type='set'
            to='6535bb5c-732f-4a3b-8329-3923aec636a5@mix.example.com'
            from='2f540478-fe93-469c-8b9c-7e4ad8fd4339@example.com/hectic'
            id='44'>
          <update-subscription xmlns='urn:xmpp:mix:core:1'>
            <subscribe node='urn:xmpp:mix:nodes:messages'/>
            <unsubscribe node='urn:xmpp:mix:nodes:presence'/>
            <subscribe node='urn:xmpp:mix:nodes:participants'/>
            <unsubscribe node='urn:xmpp:mix:nodes:info'/>
          </update-subscription>
        </iq>
      ])

      assert_stanza_receive(~x[
        <iq type='error'
            from='6535bb5c-732f-4a3b-8329-3923aec636a5@mix.example.com'
            to='2f540478-fe93-469c-8b9c-7e4ad8fd4339@example.com/hectic'
            id='44'>
          <update-subscription xmlns='urn:xmpp:mix:core:1'>
            <subscribe node='urn:xmpp:mix:nodes:messages'/>
            <unsubscribe node='urn:xmpp:mix:nodes:presence'/>
            <subscribe node='urn:xmpp:mix:nodes:participants'/>
            <unsubscribe node='urn:xmpp:mix:nodes:info'/>
          </update-subscription>
          <error type='auth'>
            <forbidden xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/>
            <text lang='en' xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'>
              forbidden access to channel
            </text>
          </error>
        </iq>
      ])

      refute_receive _, 200
    end

    test "incorrectly (not implemented?)" do
      component_received(~x[
        <iq type='set'
            to='6535bb5c-732f-4a3b-8329-3923aec636a5@mix.example.com'
            from='1a2d0b9b-9d10-4e0b-b878-9f8ab581a31f@example.com/hectic'
            id='44'>
          <update-subscription xmlns='urn:xmpp:mix:core:1'>
            <subscribe node='urn:xmpp:mix:nodes:messages'/>
            <unsubscribe node='urn:xmpp:mix:nodes:presence'/>
            <subscribe node='urn:xmpp:mix:nodes:participants'/>
            <unsubscribe node='urn:xmpp:mix:nodes:info'/>
          </update-subscription>
        </iq>
      ])

      assert_stanza_receive(~x[
        <iq type='error'
            from='6535bb5c-732f-4a3b-8329-3923aec636a5@mix.example.com'
            to='1a2d0b9b-9d10-4e0b-b878-9f8ab581a31f@example.com/hectic'
            id='44'>
          <update-subscription xmlns='urn:xmpp:mix:core:1'>
            <subscribe node='urn:xmpp:mix:nodes:messages'/>
            <unsubscribe node='urn:xmpp:mix:nodes:presence'/>
            <subscribe node='urn:xmpp:mix:nodes:participants'/>
            <unsubscribe node='urn:xmpp:mix:nodes:info'/>
          </update-subscription>
          <error type='cancel'>
            <feature-not-implemented xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/>
            <text lang='en' xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'>
              update is not supported
            </text>
          </error>
        </iq>
      ])

      refute_receive _, 200
    end
  end

  describe "set nick" do
    test "correctly" do
      component_received(~x[
        <iq type='set'
            to='6535bb5c-732f-4a3b-8329-3923aec636a5@mix.example.com'
            from='8852aa0b-b9bd-4427-aa30-9b9b4f1b0ea9@example.com/hectic'
            id='60'>
          <setnick xmlns='urn:xmpp:mix:core:1'>
            <nick>ENIAC</nick>
          </setnick>
        </iq>
      ])

      assert_stanza_receive(~x[
        <iq type='result'
            from='6535bb5c-732f-4a3b-8329-3923aec636a5@mix.example.com'
            to='8852aa0b-b9bd-4427-aa30-9b9b4f1b0ea9@example.com/hectic'
            id='60'>
          <setnick xmlns='urn:xmpp:mix:core:1'>
            <nick>ENIAC</nick>
          </setnick>
        </iq>
      ])

      channel = Mixite.Channel.get("6535bb5c-732f-4a3b-8329-3923aec636a5")
      from_jid = "8852aa0b-b9bd-4427-aa30-9b9b4f1b0ea9@example.com"

      assert_all_stanza_receive(
        for participant <- Enum.reject(channel.participants, &(&1.jid == from_jid)) do
          ~x[
            <message from='6535bb5c-732f-4a3b-8329-3923aec636a5@mix.example.com'
                     to='#{participant.jid}'
                     id='uuid'>
              <event xmlns='http://jabber.org/protocol/pubsub#event'>
                <items node='urn:xmpp:mix:nodes:participants'>
                  <item id='07f3022d-cb01-4bd8-8333-0a398be4ee8f'>
                    <participant xmlns='urn:xmpp:mix:core:1'>
                      <nick>ENIAC</nick>
                      <jid>8852aa0b-b9bd-4427-aa30-9b9b4f1b0ea9@example.com</jid>
                    </participant>
                  </item>
                </items>
              </event>
            </message>
          ]
        end
      )

      refute_receive _, 200
    end

    test "no changes" do
      component_received(~x[
        <iq type='set'
            to='6535bb5c-732f-4a3b-8329-3923aec636a5@mix.example.com'
            from='8852aa0b-b9bd-4427-aa30-9b9b4f1b0ea9@example.com/hectic'
            id='60'>
          <setnick xmlns='urn:xmpp:mix:core:1'>
            <nick>grace-hopper</nick>
          </setnick>
        </iq>
      ])

      assert_stanza_receive(~x[
        <iq type='result'
            from='6535bb5c-732f-4a3b-8329-3923aec636a5@mix.example.com'
            to='8852aa0b-b9bd-4427-aa30-9b9b4f1b0ea9@example.com/hectic'
            id='60'>
          <setnick xmlns='urn:xmpp:mix:core:1'>
            <nick>grace-hopper</nick>
          </setnick>
        </iq>
      ])

      refute_receive _, 200
    end

    test "conflict" do
      component_received(~x[
        <iq type='set'
            to='6535bb5c-732f-4a3b-8329-3923aec636a5@mix.example.com'
            from='8852aa0b-b9bd-4427-aa30-9b9b4f1b0ea9@example.com/hectic'
            id='60'>
          <setnick xmlns='urn:xmpp:mix:core:1'>
            <nick>duplicated</nick>
          </setnick>
        </iq>
      ])

      assert_stanza_receive(~x[
        <iq type='error'
            from='6535bb5c-732f-4a3b-8329-3923aec636a5@mix.example.com'
            to='8852aa0b-b9bd-4427-aa30-9b9b4f1b0ea9@example.com/hectic'
            id='60'>
          <setnick xmlns='urn:xmpp:mix:core:1'>
            <nick>duplicated</nick>
          </setnick>
          <error type='cancel'>
            <conflict xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/>
            <text lang='en' xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'>
              nickname already assigned
            </text>
          </error>
        </iq>
      ])

      refute_receive _, 200
    end

    test "unknown error" do
      component_received(~x[
        <iq type='set'
            to='6535bb5c-732f-4a3b-8329-3923aec636a5@mix.example.com'
            from='8852aa0b-b9bd-4427-aa30-9b9b4f1b0ea9@example.com/hectic'
            id='60'>
          <setnick xmlns='urn:xmpp:mix:core:1'>
            <nick>error</nick>
          </setnick>
        </iq>
      ])

      assert_stanza_receive(~x[
        <iq type='error'
            from='6535bb5c-732f-4a3b-8329-3923aec636a5@mix.example.com'
            to='8852aa0b-b9bd-4427-aa30-9b9b4f1b0ea9@example.com/hectic'
            id='60'>
          <setnick xmlns='urn:xmpp:mix:core:1'>
            <nick>error</nick>
          </setnick>
          <error type='wait'>
            <internal-server-error xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/>
            <text lang='en' xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'>
              an internal error happened
            </text>
          </error>
        </iq>
      ])

      refute_receive _, 200
    end

    test "forbidden" do
      component_received(~x[
        <iq type='set'
            to='6535bb5c-732f-4a3b-8329-3923aec636a5@mix.example.com'
            from='b587d8fc-c80a-4c41-b60f-c7f0c00cf112@example.com/hectic'
            id='60'>
          <setnick xmlns='urn:xmpp:mix:core:1'>
            <nick>ilegit</nick>
          </setnick>
        </iq>
      ])

      assert_stanza_receive(~x[
        <iq type='error'
            from='6535bb5c-732f-4a3b-8329-3923aec636a5@mix.example.com'
            to='b587d8fc-c80a-4c41-b60f-c7f0c00cf112@example.com/hectic'
            id='60'>
          <setnick xmlns='urn:xmpp:mix:core:1'>
            <nick>ilegit</nick>
          </setnick>
          <error type='auth'>
            <forbidden xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/>
            <text lang='en' xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'>
              forbidden access to channel
            </text>
          </error>
        </iq>
      ])

      refute_receive _, 200
    end
  end

  describe "join" do
    test "correctly" do
      component_received(~x[
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
      ])

      assert_stanza_receive(~x[
        <iq type='result'
            from='6535bb5c-732f-4a3b-8329-3923aec636a5@mix.example.com'
            to='7b62547e-704c-4961-8e21-9248e12c427d@example.com/hectic'
            id='44'>
          <join xmlns='urn:xmpp:mix:core:1'
                id='92cd9729-7755-4d41-a09b-7105c005aae2'>
            <subscribe node='urn:xmpp:mix:nodes:info'/>
            <subscribe node='urn:xmpp:mix:nodes:participants'/>
            <nick>third witch</nick>
          </join>
        </iq>
      ])

      to_jids = [
        # "7b62547e-704c-4961-8e21-9248e12c427d@example.com",
        "8852aa0b-b9bd-4427-aa30-9b9b4f1b0ea9@example.com",
        "c97de5c2-76ed-448d-bff9-ac4f9f32a327@example.com",
        "1a2d0b9b-9d10-4e0b-b878-9f8ab581a31f@example.com"
      ]

      stanzas =
        for to_jid <- to_jids do
          ~x[
          <message from="6535bb5c-732f-4a3b-8329-3923aec636a5@mix.example.com"
                  id="uuid"
                  to="#{to_jid}">
            <event xmlns="http://jabber.org/protocol/pubsub#event">
              <items node="urn:xmpp:mix:nodes:participants">
                <item id="92cd9729-7755-4d41-a09b-7105c005aae2">
                  <participant xmlns="urn:xmpp:mix:core:1">
                    <nick>third witch</nick>
                    <jid>7b62547e-704c-4961-8e21-9248e12c427d@example.com</jid>
                  </participant>
                </item>
              </items>
            </event>
          </message>
        ]
        end

      assert_all_stanza_receive(stanzas)

      refute_receive _, 200
    end

    test "incorrectly to no-channel" do
      component_received(~x[
        <iq type='set'
            to='mix.example.com'
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
      ])

      assert_stanza_receive(~x[
        <iq type='error'
            from='mix.example.com'
            to='7b62547e-704c-4961-8e21-9248e12c427d@example.com/hectic'
            id='44'>
          <join xmlns='urn:xmpp:mix:core:1'>
            <subscribe node='urn:xmpp:mix:nodes:messages'/>
            <subscribe node='urn:xmpp:mix:nodes:presence'/>
            <subscribe node='urn:xmpp:mix:nodes:participants'/>
            <subscribe node='urn:xmpp:mix:nodes:info'/>
            <nick>third witch</nick>
          </join>
          <error type='cancel'>
            <feature-not-implemented xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/>
            <text lang='en' xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'>
              namespace urn:xmpp:mix:core:1 requires a channel
            </text>
          </error>
        </iq>
      ])

      refute_receive _, 200
    end

    test "incorrectly bad request" do
      component_received(~x[
        <iq type='set'
            to='463e340a-9f0b-448e-af5a-964150d418d6@mix.example.com'
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
      ])

      assert_stanza_receive(~x[
        <iq type='error'
            from='463e340a-9f0b-448e-af5a-964150d418d6@mix.example.com'
            to='7b62547e-704c-4961-8e21-9248e12c427d@example.com/hectic'
            id='44'>
          <join xmlns='urn:xmpp:mix:core:1'>
            <subscribe node='urn:xmpp:mix:nodes:messages'/>
            <subscribe node='urn:xmpp:mix:nodes:presence'/>
            <subscribe node='urn:xmpp:mix:nodes:participants'/>
            <subscribe node='urn:xmpp:mix:nodes:info'/>
            <nick>third witch</nick>
          </join>
          <error type='cancel'>
            <item-not-found xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/>
            <text lang='en' xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'>
              channel not found
            </text>
          </error>
        </iq>
      ])

      refute_receive _, 200
    end

    test "incorrectly using unknown query tag" do
      component_received(~x[
        <iq type='set'
            to='6535bb5c-732f-4a3b-8329-3923aec636a5@mix.example.com'
            from='7b62547e-704c-4961-8e21-9248e12c427d@example.com/hectic'
            id='44'>
          <screw xmlns='urn:xmpp:mix:core:1'>
            <subscribe node='urn:xmpp:mix:nodes:messages'/>
            <subscribe node='urn:xmpp:mix:nodes:presence'/>
            <subscribe node='urn:xmpp:mix:nodes:participants'/>
            <subscribe node='urn:xmpp:mix:nodes:info'/>
            <nick>third witch</nick>
          </screw>
        </iq>
      ])

      assert_stanza_receive(~x[
        <iq type='error'
            from='6535bb5c-732f-4a3b-8329-3923aec636a5@mix.example.com'
            to='7b62547e-704c-4961-8e21-9248e12c427d@example.com/hectic'
            id='44'>
          <screw xmlns='urn:xmpp:mix:core:1'>
            <subscribe node='urn:xmpp:mix:nodes:messages'/>
            <subscribe node='urn:xmpp:mix:nodes:presence'/>
            <subscribe node='urn:xmpp:mix:nodes:participants'/>
            <subscribe node='urn:xmpp:mix:nodes:info'/>
            <nick>third witch</nick>
          </screw>
          <error type='cancel'>
            <feature-not-implemented xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/>
            <text lang='en' xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'>
              child unknown: screw
            </text>
          </error>
        </iq>
      ])

      refute_receive _, 200
    end

    test "incorrectly more than one child" do
      component_received(~x[
        <iq type='set'
            to='b3cd8246-67e8-44e0-a3b7-06e07ff7e643@mix.example.com'
            from='7b62547e-704c-4961-8e21-9248e12c427d@example.com/hectic'
            id='44'>
          <join xmlns='urn:xmpp:mix:core:1'>
            <subscribe node='urn:xmpp:mix:nodes:messages'/>
            <subscribe node='urn:xmpp:mix:nodes:presence'/>
            <subscribe node='urn:xmpp:mix:nodes:participants'/>
            <subscribe node='urn:xmpp:mix:nodes:info'/>
            <nick>third witch</nick>
          </join>
          <join xmlns='urn:xmpp:mix:core:1'>
            <subscribe node='urn:xmpp:mix:nodes:messages'/>
            <subscribe node='urn:xmpp:mix:nodes:presence'/>
            <subscribe node='urn:xmpp:mix:nodes:participants'/>
            <subscribe node='urn:xmpp:mix:nodes:info'/>
            <nick>third witch</nick>
          </join>
        </iq>
      ])

      assert_stanza_receive(~x[
        <iq type='error'
            from='b3cd8246-67e8-44e0-a3b7-06e07ff7e643@mix.example.com'
            to='7b62547e-704c-4961-8e21-9248e12c427d@example.com/hectic'
            id='44'>
          <join xmlns='urn:xmpp:mix:core:1'>
            <subscribe node='urn:xmpp:mix:nodes:messages'/>
            <subscribe node='urn:xmpp:mix:nodes:presence'/>
            <subscribe node='urn:xmpp:mix:nodes:participants'/>
            <subscribe node='urn:xmpp:mix:nodes:info'/>
            <nick>third witch</nick>
          </join>
          <join xmlns='urn:xmpp:mix:core:1'>
            <subscribe node='urn:xmpp:mix:nodes:messages'/>
            <subscribe node='urn:xmpp:mix:nodes:presence'/>
            <subscribe node='urn:xmpp:mix:nodes:participants'/>
            <subscribe node='urn:xmpp:mix:nodes:info'/>
            <nick>third witch</nick>
          </join>
          <error type='cancel'>
            <feature-not-implemented xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/>
            <text lang='en' xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'>
              iq must have only and at least one child
            </text>
          </error>
        </iq>
      ])

      refute_receive _, 200
    end

    test "incorrectly forbidden" do
      component_received(~x[
        <iq type='set'
            to='6535bb5c-732f-4a3b-8329-3923aec636a5@mix.example.com'
            from='forbid@example.com/hectic'
            id='77'>
          <join xmlns='urn:xmpp:mix:core:1'>
            <subscribe node='urn:xmpp:mix:nodes:messages'/>
            <subscribe node='urn:xmpp:mix:nodes:presence'/>
            <subscribe node='urn:xmpp:mix:nodes:participants'/>
            <subscribe node='urn:xmpp:mix:nodes:info'/>
            <nick>99th witch</nick>
          </join>
        </iq>
      ])

      assert_stanza_receive(~x[
        <iq type='error'
            from='6535bb5c-732f-4a3b-8329-3923aec636a5@mix.example.com'
            to='forbid@example.com/hectic'
            id='77'>
          <join xmlns='urn:xmpp:mix:core:1'>
            <subscribe node='urn:xmpp:mix:nodes:messages'/>
            <subscribe node='urn:xmpp:mix:nodes:presence'/>
            <subscribe node='urn:xmpp:mix:nodes:participants'/>
            <subscribe node='urn:xmpp:mix:nodes:info'/>
            <nick>99th witch</nick>
          </join>
          <error type='auth'>
            <forbidden xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/>
            <text lang='en' xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'>
              forbidden access to channel
            </text>
          </error>
        </iq>
      ])

      refute_receive _, 200
    end
  end

  describe "leave" do
    test "correctly" do
      component_received(~x[
        <iq type='set'
            to='c5f74c1b-11e6-4a81-ab6a-afc598180b5a@mix.example.com'
            from='e784345c-4bed-4ce0-9610-e6f57b9ac6f2@example.com/hectic'
            id='50'>
          <leave xmlns='urn:xmpp:mix:core:1'/>
        </iq>
      ])

      to_jids = [
        "2f540478-fe93-469c-8b9c-7e4ad8fd4339@example.com",
        "f8e744de-3d1b-4528-9cfd-3fa111f7f626@example.com"
      ]

      stanzas =
        [~x[
          <iq type='result'
              from='c5f74c1b-11e6-4a81-ab6a-afc598180b5a@mix.example.com'
              to='e784345c-4bed-4ce0-9610-e6f57b9ac6f2@example.com/hectic'
              id='50'>
            <leave xmlns='urn:xmpp:mix:core:1'/>
          </iq>
        ]] ++
          for to_jid <- to_jids do
            ~x[
          <message from="c5f74c1b-11e6-4a81-ab6a-afc598180b5a@mix.example.com"
                  id="uuid"
                  to="#{to_jid}">
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

      assert_all_stanza_receive(stanzas)

      refute_receive _, 200
    end

    test "correctly with extra payload" do
      component_received(~x[
        <iq type='set'
            to='c5f74c1b-11e6-4a81-ab6a-afc598180b5a@mix.example.com'
            from='f8e744de-3d1b-4528-9cfd-3fa111f7f626@example.com/hectic'
            id='50'>
          <leave xmlns='urn:xmpp:mix:core:1'/>
        </iq>
      ])

      to_jids = [
        "2f540478-fe93-469c-8b9c-7e4ad8fd4339@example.com",
        "e784345c-4bed-4ce0-9610-e6f57b9ac6f2@example.com"
      ]

      stanzas =
        [~x[
          <iq type='result'
              from='c5f74c1b-11e6-4a81-ab6a-afc598180b5a@mix.example.com'
              to='f8e744de-3d1b-4528-9cfd-3fa111f7f626@example.com/hectic'
              id='50'>
            <leave xmlns='urn:xmpp:mix:core:1'/>
          </iq>
        ]] ++
          for to_jid <- to_jids do
            ~x[
          <message from="c5f74c1b-11e6-4a81-ab6a-afc598180b5a@mix.example.com"
                  id="uuid"
                  to="#{to_jid}">
            <event xmlns="http://jabber.org/protocol/pubsub#event">
              <items node="urn:xmpp:mix:nodes:participants">
                <retract id="b98dd64f-0f2b-4446-8889-3fc7d3f73113">
                  <jid>f8e744de-3d1b-4528-9cfd-3fa111f7f626@example.com</jid>
                </retract>
              </items>
            </event>
            <store xmlns='urn:xmpp:hints'/>
          </message>
        ]
          end

      assert_all_stanza_receive(stanzas)

      refute_receive _, 200
    end

    test "incorrectly: not found" do
      component_received(~x[
        <iq type='set'
            to='00000000-11e6-4a81-ab6a-afc598180b5a@mix.example.com'
            from='e784345c-4bed-4ce0-9610-e6f57b9ac6f2@example.com/hectic'
            id='50'>
          <leave xmlns='urn:xmpp:mix:core:1'/>
        </iq>
      ])

      assert_stanza_receive(~x[
        <iq type='error'
            from='00000000-11e6-4a81-ab6a-afc598180b5a@mix.example.com'
            to='e784345c-4bed-4ce0-9610-e6f57b9ac6f2@example.com/hectic'
            id='50'>
          <leave xmlns='urn:xmpp:mix:core:1'/>
          <error type='cancel'>
            <item-not-found xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/>
            <text lang='en' xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'>
              channel not found
            </text>
          </error>
        </iq>
      ])

      refute_receive _, 200
    end

    test "incorrectly: forbidden" do
      component_received(~x[
        <iq type='set'
            to='c5f74c1b-11e6-4a81-ab6a-afc598180b5a@mix.example.com'
            from='00000000-4bed-4ce0-9610-e6f57b9ac6f2@example.com/hectic'
            id='50'>
          <leave xmlns='urn:xmpp:mix:core:1'/>
        </iq>
      ])

      assert_stanza_receive(~x[
        <iq type='error'
            from='c5f74c1b-11e6-4a81-ab6a-afc598180b5a@mix.example.com'
            to='00000000-4bed-4ce0-9610-e6f57b9ac6f2@example.com/hectic'
            id='50'>
          <leave xmlns='urn:xmpp:mix:core:1'/>
          <error type='auth'>
            <forbidden xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/>
            <text lang='en' xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'>
              forbidden access to channel
            </text>
          </error>
        </iq>
      ])

      refute_receive _, 200
    end

    test "incorrectly: not implemented?" do
      component_received(~x[
        <iq type='set'
            to='c5f74c1b-11e6-4a81-ab6a-afc598180b5a@mix.example.com'
            from='2f540478-fe93-469c-8b9c-7e4ad8fd4339@example.com/hectic'
            id='50'>
          <leave xmlns='urn:xmpp:mix:core:1'/>
        </iq>
      ])

      assert_stanza_receive(~x[
        <iq type='error'
            from='c5f74c1b-11e6-4a81-ab6a-afc598180b5a@mix.example.com'
            to='2f540478-fe93-469c-8b9c-7e4ad8fd4339@example.com/hectic'
            id='50'>
          <leave xmlns='urn:xmpp:mix:core:1'/>
          <error type='cancel'>
            <feature-not-implemented xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/>
            <text lang='en' xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'>
              leave is not supported
            </text>
          </error>
        </iq>
      ])

      refute_receive _, 200
    end
  end
end
