defmodule Mixite.Xmpp.CoreControllerTest do
  use Exampple.Router.ConnCase

  import Exampple.Xml.Xmlel, only: [sigil_x: 2]

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
            <subscribe node='urn:xmpp:mix:nodes:presence'/>
            <subscribe node='urn:xmpp:mix:nodes:participants'/>
            <subscribe node='urn:xmpp:mix:nodes:info'/>
            <nick>third witch</nick>
          </join>
        </iq>
      ]
    end
  end
end
