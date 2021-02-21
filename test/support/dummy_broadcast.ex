defmodule Mixite.DummyBroadcast do
  use Mixite.Broadcast
  import Exampple.Xml.Xmlel, only: [sigil_x: 2]
  alias Exampple.Xml.Xmlel

  @impl Mixite.Broadcast
  def extra_payload(
        _channel,
        _user_jid,
        _from_jid,
        [
          %Xmlel{
            name: "event",
            children: [
              %Xmlel{
                name: "items",
                children: [
                  %Xmlel{
                    name: "retract",
                    children: [
                      %Xmlel{
                        name: "jid",
                        children: [
                          "f8e744de-3d1b-4528-9cfd-3fa111f7f626@example.com"
                        ]
                      }
                    ]
                  }
                ]
              }
            ]
          }
        ] = payload,
        _opts
      ) do
    payload ++ [~x[<store xmlns='urn:xmpp:hints'/>]]
  end

  def extra_payload(_channel, _user_jid, _from_jid, payload, _opts) do
    payload
  end
end
