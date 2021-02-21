defmodule Mixite.Xmpp.PubsubControllerTest do
  use Exampple.Router.ConnCase

  import Exampple.Xml.Xmlel, only: [sigil_x: 2]

  describe "pubsub set: " do
    test "nodes:info set for a channel" do
      component_received(~x[
        <iq from='4b2f6c32-fa80-4d97-aeec-db8e043507fe@example.com/UUID-c8y/1573'
            id='111'
            to='be89d464-87d1-4351-bdff-a2cdd7bdb975@mixite.example.com'
            type='set'>
          <pubsub xmlns='http://jabber.org/protocol/pubsub'>
            <publish node='urn:xmpp:mix:nodes:info'>
              <item>
                <x xmlns='jabber:x:data' type='submit'>
                  <field var='FORM_TYPE' type='hidden'>
                    <value>urn:xmpp:mix:core:1</value>
                  </field>
                  <field var='Name'>
                    <value>berkeley</value>
                  </field>
                  <field var='Description'>
                    <value>Berkeley University</value>
                  </field>
                </x>
              </item>
            </publish>
          </pubsub>
        </iq>
      ])

      assert_stanza_receive(~x[
        <iq from='be89d464-87d1-4351-bdff-a2cdd7bdb975@mixite.example.com'
            id='111'
            to='4b2f6c32-fa80-4d97-aeec-db8e043507fe@example.com/UUID-c8y/1573'
            type='result'>
          <pubsub xmlns='http://jabber.org/protocol/pubsub'>
            <publish node='urn:xmpp:mix:nodes:info'>
              <item id='2020-09-23T00:36:20Z' xmlns='urn:xmpp:mix:core:1'/>
            </publish>
          </pubsub>
        </iq>
      ])

      channel = Mixite.Channel.get("be89d464-87d1-4351-bdff-a2cdd7bdb975")

      assert_all_stanza_receive(
        for participant <- channel.participants do
          ~x[
            <message from='be89d464-87d1-4351-bdff-a2cdd7bdb975@mixite.example.com'
                     id='uuid'
                     to='#{participant.jid}'>
              <event xmlns='http://jabber.org/protocol/pubsub#event'>
                <items node='urn:xmpp:mix:nodes:info'>
                  <item id='2020-09-23T00:36:20Z'>
                    <x xmlns='jabber:x:data' type='result'>
                      <field var='FORM_TYPE' type='hidden'>
                        <value>urn:xmpp:mix:core:1</value>
                      </field>
                      <field var='Name'>
                        <value>berkeley</value>
                      </field>
                      <field var='Description'>
                        <value>Berkeley University</value>
                      </field>
                      <field var='Created At'>
                        <value>2020-09-23T00:36:20Z</value>
                      </field>
                    </x>
                  </item>
                </items>
              </event>
            </message>
          ]
        end
      )

      refute_receive _, 200
    end

    test "nodes:config set for a channel" do
      component_received(~x[
        <iq from='4b2f6c32-fa80-4d97-aeec-db8e043507fe@example.com/UUID-c8y/1573'
            id='111'
            to='be89d464-87d1-4351-bdff-a2cdd7bdb975@mixite.example.com'
            type='set'>
          <pubsub xmlns='http://jabber.org/protocol/pubsub'>
            <publish node='urn:xmpp:mix:nodes:config'>
              <item>
                <x xmlns='jabber:x:data' type='submit'>
                  <field var='FORM_TYPE' type='hidden'>
                    <value>urn:xmpp:mix:admin:0</value>
                  </field>
                  <field var='Owner'>
                    <value>4b2f6c32-fa80-4d97-aeec-db8e043507fe@example.com</value>
                    <value>c3b10914-905d-4920-a5cd-146a0061e478@example.com</value>
                  </field>
                  <field var='Administrator'>
                    <value>c3b10914-905d-4920-a5cd-146a0061e478@example.com</value>
                  </field>
                </x>
              </item>
            </publish>
          </pubsub>
        </iq>
      ])

      assert_stanza_receive(~x[
        <iq from='be89d464-87d1-4351-bdff-a2cdd7bdb975@mixite.example.com'
            id='111'
            to='4b2f6c32-fa80-4d97-aeec-db8e043507fe@example.com/UUID-c8y/1573'
            type='result'>
          <pubsub xmlns='http://jabber.org/protocol/pubsub'>
            <publish node='urn:xmpp:mix:nodes:config'>
              <item id='2020-09-23T00:36:20Z' xmlns='urn:xmpp:mix:admin:0'/>
            </publish>
          </pubsub>
        </iq>
      ])

      jids = [
        "4b2f6c32-fa80-4d97-aeec-db8e043507fe@example.com",
        "c3b10914-905d-4920-a5cd-146a0061e478@example.com"
      ]

      assert_all_stanza_receive(
        for jid <- jids do
          ~x[
            <message from='be89d464-87d1-4351-bdff-a2cdd7bdb975@mixite.example.com'
                     id='uuid'
                     to='#{jid}'>
              <event xmlns='http://jabber.org/protocol/pubsub#event'>
                <items node='urn:xmpp:mix:nodes:config' xmlns='urn:xmpp:mix:admin:0'>
                  <item id='2020-09-23T00:36:20Z'>
                    <x xmlns='jabber:x:data' type='result'>
                      <field var='FORM_TYPE' type='hidden'>
                        <value>urn:xmpp:mix:admin:0</value>
                      </field>
                      <field var='Owner'>
                        <value>4b2f6c32-fa80-4d97-aeec-db8e043507fe@example.com</value>
                        <value>c3b10914-905d-4920-a5cd-146a0061e478@example.com</value>
                      </field>
                      <field var='Administrator'>
                        <value>c3b10914-905d-4920-a5cd-146a0061e478@example.com</value>
                      </field>
                      <field var="Nodes Present">
                        <value>participants</value>
                        <value>information</value>
                        <value>allowed</value>
                        <value>banned</value>
                      </field>
                      <field var="Participants Node Subscription">
                        <value>participants</value>
                      </field>
                      <field var="Information Node Subscription">
                        <value>participants</value>
                      </field>
                      <field var="Allowed Node Subscription">
                        <value>administrators</value>
                      </field>
                      <field var="Banned Node Subscription">
                        <value>administrators</value>
                      </field>
                      <field var="Configuration Node Access">
                        <value>participants</value>
                      </field>
                      <field var="Information Node Update Rights">
                        <value>owners</value>
                      </field>
                      <field var="Avatar Nodes Update Rights">
                        <value>admins</value>
                      </field>
                      <field var="Mandatory Nicks">
                        <value>true</value>
                      </field>
                      <field type="hidden" var="ENV">
                        <value>test</value>
                      </field>
                      <field var="Messages Node Subscription">
                        <value>allowed</value>
                      </field>
                      <field var="No Private Messages">
                        <value>true</value>
                      </field>
                    </x>
                  </item>
                </items>
              </event>
            </message>
          ]
        end
      )

      refute_receive _, 200
    end

    test "nodes:info set for a channel forbidden" do
      component_received(~x[
        <iq from='c3b10914-905d-4920-a5cd-146a0061e478@example.com/UUID-c8y/1573'
            id='111'
            to='be89d464-87d1-4351-bdff-a2cdd7bdb975@mixite.example.com'
            type='set'>
          <pubsub xmlns='http://jabber.org/protocol/pubsub'>
            <publish node='urn:xmpp:mix:nodes:info'>
              <item>
                <x xmlns='jabber:x:data' type='submit'>
                  <field var='FORM_TYPE' type='hidden'>
                    <value>urn:xmpp:mix:core:1</value>
                  </field>
                  <field var='Name'>
                    <value>berkeley</value>
                  </field>
                  <field var='Description'>
                    <value>Berkeley University</value>
                  </field>
                </x>
              </item>
            </publish>
          </pubsub>
        </iq>
      ])

      assert_stanza_receive(~x[
        <iq to='c3b10914-905d-4920-a5cd-146a0061e478@example.com/UUID-c8y/1573'
            id='111'
            from='be89d464-87d1-4351-bdff-a2cdd7bdb975@mixite.example.com'
            type='error'>
          <pubsub xmlns='http://jabber.org/protocol/pubsub'>
            <publish node='urn:xmpp:mix:nodes:info'>
              <item>
                <x xmlns='jabber:x:data' type='submit'>
                  <field var='FORM_TYPE' type='hidden'>
                    <value>urn:xmpp:mix:core:1</value>
                  </field>
                  <field var='Name'>
                    <value>berkeley</value>
                  </field>
                  <field var='Description'>
                    <value>Berkeley University</value>
                  </field>
                </x>
              </item>
            </publish>
          </pubsub>
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

    test "nodes:allowed publish allowed user" do
      component_received(~x[
        <iq from='4b2f6c32-fa80-4d97-aeec-db8e043507fe@example.com/UUID-c8y/1573'
            id='111'
            to='be89d464-87d1-4351-bdff-a2cdd7bdb975@mixite.example.com'
            type='set'>
          <pubsub xmlns='http://jabber.org/protocol/pubsub'>
            <publish node='urn:xmpp:mix:nodes:allowed'>
              <item id='7c5ea0bf-ec6f-46e3-8f6b-c5e8aa80c968@example.com'/>
            </publish>
          </pubsub>
        </iq>
      ])

      assert_stanza_receive(~x[
        <iq to='4b2f6c32-fa80-4d97-aeec-db8e043507fe@example.com/UUID-c8y/1573'
            id='111'
            from='be89d464-87d1-4351-bdff-a2cdd7bdb975@mixite.example.com'
            type='result'>
          <pubsub xmlns='http://jabber.org/protocol/pubsub'/>
        </iq>
      ])

      jids = [
        "4b2f6c32-fa80-4d97-aeec-db8e043507fe@example.com",
        "c3b10914-905d-4920-a5cd-146a0061e478@example.com"
      ]

      assert_all_stanza_receive(
        for jid <- jids do
          ~x[
            <message from='be89d464-87d1-4351-bdff-a2cdd7bdb975@mixite.example.com'
                     id='uuid'
                     to='#{jid}'>
              <event xmlns="http://jabber.org/protocol/pubsub#event">
                <items node="urn:xmpp:mix:nodes:allowed">
                  <item id="4b2f6c32-fa80-4d97-aeec-db8e043507fe@example.com"/>
                  <item id='7c5ea0bf-ec6f-46e3-8f6b-c5e8aa80c968@example.com'/>
                  <item id="c3b10914-905d-4920-a5cd-146a0061e478@example.com"/>
                </items>
              </event>
            </message>
          ]
        end
      )

      refute_receive _, 500
    end
  end

  describe "pubsub get: " do
    test "nodes:info from a channel" do
      component_received(~x[
        <iq from='c3b10914-905d-4920-a5cd-146a0061e478@example.com/UUID-c8y/1573'
            id='kl2fax27'
            to='be89d464-87d1-4351-bdff-a2cdd7bdb975@mixite.example.com'
            type='get'>
          <pubsub xmlns='http://jabber.org/protocol/pubsub'>
            <items node='urn:xmpp:mix:nodes:info'/>
          </pubsub>
        </iq>
      ])

      assert_stanza_receive(~x[
        <iq from='be89d464-87d1-4351-bdff-a2cdd7bdb975@mixite.example.com'
            id='kl2fax27'
            to='c3b10914-905d-4920-a5cd-146a0061e478@example.com/UUID-c8y/1573'
            type='result'>
          <pubsub xmlns='http://jabber.org/protocol/pubsub'>
            <items node='urn:xmpp:mix:nodes:info'>
              <item id='2020-09-23T00:36:20Z'>
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
                  <field var='Created At'>
                    <value>2020-09-23T00:36:20Z</value>
                  </field>
                </x>
              </item>
            </items>
          </pubsub>
        </iq>
      ])

      refute_receive _, 200
    end

    test "nodes:info from a non-user" do
      component_received(~x[
        <iq from='user-id@example.com/UUID-c8y/1573'
            id='kl2fax27'
            to='be89d464-87d1-4351-bdff-a2cdd7bdb975@mixite.example.com'
            type='get'>
          <pubsub xmlns='http://jabber.org/protocol/pubsub'>
            <items node='urn:xmpp:mix:nodes:info'/>
          </pubsub>
        </iq>
      ])

      assert_stanza_receive(~x[
        <iq from='be89d464-87d1-4351-bdff-a2cdd7bdb975@mixite.example.com'
            id='kl2fax27'
            to='user-id@example.com/UUID-c8y/1573'
            type='error'>
          <pubsub xmlns='http://jabber.org/protocol/pubsub'>
            <items node='urn:xmpp:mix:nodes:info'/>
          </pubsub>
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

    test "nodes:info channel not found" do
      component_received(~x[
        <iq from='user-id@example.com/UUID-c8y/1573'
            id='kl2fax27'
            to='inexistent-channel@mixite.example.com'
            type='get'>
          <pubsub xmlns='http://jabber.org/protocol/pubsub'>
            <items node='urn:xmpp:mix:nodes:info'/>
          </pubsub>
        </iq>
      ])

      assert_stanza_receive(~x[
        <iq from='inexistent-channel@mixite.example.com'
            id='kl2fax27'
            to='user-id@example.com/UUID-c8y/1573'
            type='error'>
          <pubsub xmlns='http://jabber.org/protocol/pubsub'>
            <items node='urn:xmpp:mix:nodes:info'/>
          </pubsub>
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

    test "nodes:config from a channel" do
      component_received(~x[
        <iq from='c3b10914-905d-4920-a5cd-146a0061e478@example.com/UUID-c8y/1573'
            id='kl2fax27'
            to='be89d464-87d1-4351-bdff-a2cdd7bdb975@mixite.example.com'
            type='get'>
          <pubsub xmlns='http://jabber.org/protocol/pubsub'>
            <items node='urn:xmpp:mix:nodes:config'/>
          </pubsub>
        </iq>
      ])

      assert_stanza_receive(~x[
        <iq from='be89d464-87d1-4351-bdff-a2cdd7bdb975@mixite.example.com'
            id='kl2fax27'
            to='c3b10914-905d-4920-a5cd-146a0061e478@example.com/UUID-c8y/1573'
            type='result'>
          <pubsub xmlns='http://jabber.org/protocol/pubsub'>
            <items xmlns='urn:xmpp:mix:admin:0' node='urn:xmpp:mix:nodes:config'>
              <item id='2020-09-23T00:36:20Z'>
                <x xmlns='jabber:x:data' type='result'>
                  <field var='FORM_TYPE' type='hidden'>
                    <value>urn:xmpp:mix:admin:0</value>
                  </field>
                  <field var='Owner'>
                    <value>4b2f6c32-fa80-4d97-aeec-db8e043507fe@example.com</value>
                  </field>
                  <field var="Nodes Present">
                    <value>participants</value>
                    <value>information</value>
                    <value>allowed</value>
                    <value>banned</value>
                  </field>
                  <field var="Participants Node Subscription">
                    <value>participants</value>
                  </field>
                  <field var="Information Node Subscription">
                    <value>participants</value>
                  </field>
                  <field var="Allowed Node Subscription">
                    <value>administrators</value>
                  </field>
                  <field var="Banned Node Subscription">
                    <value>administrators</value>
                  </field>
                  <field var="Configuration Node Access">
                    <value>participants</value>
                  </field>
                  <field var="Information Node Update Rights">
                    <value>owners</value>
                  </field>
                  <field var="Avatar Nodes Update Rights">
                    <value>admins</value>
                  </field>
                  <field var="Mandatory Nicks">
                    <value>true</value>
                  </field>
                  <field var='ENV' type='hidden'>
                    <value>test</value>
                  </field>
                  <field var='Messages Node Subscription'>
                    <value>allowed</value>
                  </field>
                  <field var='No Private Messages'>
                    <value>true</value>
                  </field>
                </x>
              </item>
            </items>
          </pubsub>
        </iq>
      ])

      refute_receive _, 200
    end

    test "nodes:config from a channel with administrators" do
      component_received(~x[
        <iq from='8852aa0b-b9bd-4427-aa30-9b9b4f1b0ea9@example.com/UUID-c8y/1573'
            id='kl2fax27'
            to='3cfd82c0-8453-4198-a706-dbec5692dc43@mixite.example.com'
            type='get'>
          <pubsub xmlns='http://jabber.org/protocol/pubsub'>
            <items node='urn:xmpp:mix:nodes:config'/>
          </pubsub>
        </iq>
      ])

      assert_stanza_receive(~x[
        <iq from='3cfd82c0-8453-4198-a706-dbec5692dc43@mixite.example.com'
            id='kl2fax27'
            to='8852aa0b-b9bd-4427-aa30-9b9b4f1b0ea9@example.com/UUID-c8y/1573'
            type='result'>
          <pubsub xmlns='http://jabber.org/protocol/pubsub'>
            <items xmlns='urn:xmpp:mix:admin:0' node='urn:xmpp:mix:nodes:config'>
              <item id='2020-10-09T00:45:55Z'>
                <x xmlns='jabber:x:data' type='result'>
                  <field var='FORM_TYPE' type='hidden'>
                    <value>urn:xmpp:mix:admin:0</value>
                  </field>
                  <field var='Owner'>
                    <value>8852aa0b-b9bd-4427-aa30-9b9b4f1b0ea9@example.com</value>
                  </field>
                  <field var='Administrator'>
                    <value>c97de5c2-76ed-448d-bff9-ac4f9f32a327@example.com</value>
                  </field>
                  <field var="Nodes Present">
                    <value>participants</value>
                    <value>information</value>
                    <value>allowed</value>
                    <value>banned</value>
                  </field>
                  <field var="Participants Node Subscription">
                    <value>participants</value>
                  </field>
                  <field var="Information Node Subscription">
                    <value>participants</value>
                  </field>
                  <field var="Allowed Node Subscription">
                    <value>administrators</value>
                  </field>
                  <field var="Banned Node Subscription">
                    <value>administrators</value>
                  </field>
                  <field var="Configuration Node Access">
                    <value>owners</value>
                  </field>
                  <field var="Information Node Update Rights">
                    <value>admins</value>
                  </field>
                  <field var="Avatar Nodes Update Rights">
                    <value>admins</value>
                  </field>
                  <field var="Mandatory Nicks">
                    <value>true</value>
                  </field>
                  <field var='ENV' type='hidden'>
                    <value>test</value>
                  </field>
                  <field var='Messages Node Subscription'>
                    <value>allowed</value>
                  </field>
                  <field var='No Private Messages'>
                    <value>true</value>
                  </field>
                </x>
              </item>
            </items>
          </pubsub>
        </iq>
      ])

      refute_receive _, 200
    end

    test "nodes:config from a non-participant" do
      component_received(~x[
        <iq from='user-id@example.com/UUID-c8y/1573'
            id='kl2fax27'
            to='3cfd82c0-8453-4198-a706-dbec5692dc43@mixite.example.com'
            type='get'>
          <pubsub xmlns='http://jabber.org/protocol/pubsub'>
            <items node='urn:xmpp:mix:nodes:config'/>
          </pubsub>
        </iq>
      ])

      assert_stanza_receive(~x[
        <iq from='3cfd82c0-8453-4198-a706-dbec5692dc43@mixite.example.com'
            id='kl2fax27'
            to='user-id@example.com/UUID-c8y/1573'
            type='error'>
          <pubsub xmlns='http://jabber.org/protocol/pubsub'>
            <items node='urn:xmpp:mix:nodes:config'/>
          </pubsub>
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

    test "nodes:participants from a channel" do
      component_received(~x[
        <iq from='c3b10914-905d-4920-a5cd-146a0061e478@example.com/UUID-c8y/1573'
            id='kl2fax27'
            to='be89d464-87d1-4351-bdff-a2cdd7bdb975@mixite.example.com'
            type='get'>
          <pubsub xmlns='http://jabber.org/protocol/pubsub'>
            <items node='urn:xmpp:mix:nodes:participants'/>
          </pubsub>
        </iq>
      ])

      assert_stanza_receive(~x[
        <iq from='be89d464-87d1-4351-bdff-a2cdd7bdb975@mixite.example.com'
            id='kl2fax27'
            to='c3b10914-905d-4920-a5cd-146a0061e478@example.com/UUID-c8y/1573'
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
      ])

      refute_receive _, 200
    end

    test "custom node from a channel" do
      component_received(~x[
        <iq from='c3b10914-905d-4920-a5cd-146a0061e478@example.com/UUID-c8y/1573'
            id='kl2fax27'
            to='be89d464-87d1-4351-bdff-a2cdd7bdb975@mixite.example.com'
            type='get'>
          <pubsub xmlns='http://jabber.org/protocol/pubsub'>
            <items node='urn:xmpp:mixite:0'/>
          </pubsub>
        </iq>
      ])

      assert_stanza_receive(~x[
        <iq from='be89d464-87d1-4351-bdff-a2cdd7bdb975@mixite.example.com'
            id='kl2fax27'
            to='c3b10914-905d-4920-a5cd-146a0061e478@example.com/UUID-c8y/1573'
            type='result'>
          <pubsub xmlns='http://jabber.org/protocol/pubsub'>
            <items node='urn:xmpp:mixite:0'>
              <mixite>Hello world!</mixite>
            </items>
          </pubsub>
        </iq>
      ])

      refute_receive _, 200
    end

    test "custom node from a channel with multiple items" do
      component_received(~x[
        <iq from='c3b10914-905d-4920-a5cd-146a0061e478@example.com/UUID-c8y/1573'
            id='kl2fax27'
            to='be89d464-87d1-4351-bdff-a2cdd7bdb975@mixite.example.com'
            type='get'>
          <pubsub xmlns='http://jabber.org/protocol/pubsub'>
            <items node='urn:xmpp:mixite:1'/>
          </pubsub>
        </iq>
      ])

      assert_stanza_receive(~x[
        <iq from='be89d464-87d1-4351-bdff-a2cdd7bdb975@mixite.example.com'
            id='kl2fax27'
            to='c3b10914-905d-4920-a5cd-146a0061e478@example.com/UUID-c8y/1573'
            type='result'>
          <pubsub xmlns='http://jabber.org/protocol/pubsub'>
            <items node='urn:xmpp:mixite:1'>
              <mixite>Hello world!</mixite>
              <mixite>Hola mundo!</mixite>
              <mixite>Ciao mondo!</mixite>
            </items>
          </pubsub>
        </iq>
      ])

      refute_receive _, 200
    end

    test "custom node generating error" do
      component_received(~x[
        <iq from='c3b10914-905d-4920-a5cd-146a0061e478@example.com/UUID-c8y/1573'
            id='kl2fax27'
            to='be89d464-87d1-4351-bdff-a2cdd7bdb975@mixite.example.com'
            type='get'>
          <pubsub xmlns='http://jabber.org/protocol/pubsub'>
            <items node='urn:xmpp:mixite:error:0'/>
          </pubsub>
        </iq>
      ])

      assert_stanza_receive(~x[
        <iq from='be89d464-87d1-4351-bdff-a2cdd7bdb975@mixite.example.com'
            id='kl2fax27'
            to='c3b10914-905d-4920-a5cd-146a0061e478@example.com/UUID-c8y/1573'
            type='error'>
          <pubsub xmlns='http://jabber.org/protocol/pubsub'>
            <items node='urn:xmpp:mixite:error:0'/>
          </pubsub>
          <error type='cancel'>
            <feature-not-implemented xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/>
            <text lang='en' xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'>
              mixite error!
            </text>
          </error>
        </iq>
      ])

      refute_receive _, 200
    end

    test "node not defined" do
      component_received(~x[
        <iq from='c3b10914-905d-4920-a5cd-146a0061e478@example.com/UUID-c8y/1573'
            id='kl2fax27'
            to='be89d464-87d1-4351-bdff-a2cdd7bdb975@mixite.example.com'
            type='get'>
          <pubsub xmlns='http://jabber.org/protocol/pubsub'>
            <items node='urn:xmpp:mixite:100'/>
          </pubsub>
        </iq>
      ])

      assert_stanza_receive(~x[
        <iq from='be89d464-87d1-4351-bdff-a2cdd7bdb975@mixite.example.com'
            id='kl2fax27'
            to='c3b10914-905d-4920-a5cd-146a0061e478@example.com/UUID-c8y/1573'
            type='error'>
          <pubsub xmlns='http://jabber.org/protocol/pubsub'>
            <items node='urn:xmpp:mixite:100'/>
          </pubsub>
          <error type='cancel'>
            <feature-not-implemented xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/>
            <text lang='en' xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'>
              urn:xmpp:mixite:100 not implemented
            </text>
          </error>
        </iq>
      ])

      refute_receive _, 200
    end
  end
end
