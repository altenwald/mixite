defmodule Mixite.DummyGroupchat do
  use Mixite.Groupchat

  alias Mixite.Groupchat

  @nodes ~w[
    config
    messages
    participants
    presence
  ]
  @data %{
    "be89d464-87d1-4351-bdff-a2cdd7bdb975" => %Groupchat{
      id: "be89d464-87d1-4351-bdff-a2cdd7bdb975",
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
    },
    "6535bb5c-732f-4a3b-8329-3923aec636a5" => %Groupchat{
      id: "6535bb5c-732f-4a3b-8329-3923aec636a5",
      name: "prom 2020",
      description: "online prom!",
      nodes: @nodes,
      contact: nil,
      participants: [
        {
          "07f3022d-cb01-4bd8-8333-0a398be4ee8f",
          "grace-hopper",
          "8852aa0b-b9bd-4427-aa30-9b9b4f1b0ea9@example.com"
        },
        {
          "0d26525e-f3cc-462c-94d1-61a5beafb033",
          "john-von-neumann",
          "c97de5c2-76ed-448d-bff9-ac4f9f32a327@example.com"
        }
      ],
      updated_at: ~N[2020-10-09 00:45:55.363444],
      inserted_at: ~N[2020-10-09 00:45:55.363444]
    }
  }

  def get(id) do
    @data[id]
  end

  def join(%Groupchat{id: "6535bb5c-732f-4a3b-8329-3923aec636a5"}, _jid, _nick, nodes) do
    intersect_nodes = Enum.sort(nodes -- (nodes -- @nodes))
    {"92cd9729-7755-4d41-a09b-7105c005aae2", intersect_nodes}
  end

  def update(%Groupchat{nodes: nodes}, _user_id, add_nodes, rem_nodes) do
    add_nodes = add_nodes -- nodes
    rem_nodes = rem_nodes -- (rem_nodes -- nodes)
    {:ok, {add_nodes, rem_nodes}}
  end
end
