defmodule Mixite.DummyGroupchat do
  use Mixite.Groupchat

  alias Mixite.Groupchat

  @nodes [:presence, :participants, :messages, :config]
  @data %{
    "be89d464-87d1-4351-bdff-a2cdd7bdb975" => %Groupchat{
      name: "pennsylvania",
      description: "Pennsylvania University",
      nodes: @nodes,
      contact: nil,
      participants: [
        {
          "ac3c30e4-e1d5-489f-80f4-671735f444ed",
          "john-eckert",
          "4b2f6c32-fa80-4d97-aeec-db8e043507fe@example.com"
        },
        {
          "2846ff3f-6b90-48e5-9aad-c3782393d8be",
          "john-mauchly",
          "c3b10914-905d-4920-a5cd-146a0061e478@example.com"
        }
      ],
      updated_at: ~N[2020-09-23 00:36:20.363444],
      inserted_at: ~N[2020-09-23 00:36:20.363444]
    }
  }

  def get(id) do
    @data[id]
  end

  def join("b665a43d-0dbd-4b9d-8610-a33b2917bc24", _jid, _nick) do
    {"92cd9729-7755-4d41-a09b-7105c005aae2", @nodes}
  end
end
