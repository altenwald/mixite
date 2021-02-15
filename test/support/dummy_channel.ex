defmodule Mixite.DummyChannel do
  use Mixite.Channel

  alias Exampple.Xml.Xmlel

  @nodes ~w[
    config
    messages
    participants
    presence
  ]
  @data %{
    "be89d464-87d1-4351-bdff-a2cdd7bdb975" => %Channel{
      id: "be89d464-87d1-4351-bdff-a2cdd7bdb975",
      name: "pennsylvania",
      description: "Pennsylvania University",
      nodes: @nodes,
      contact: nil,
      owners: ["4b2f6c32-fa80-4d97-aeec-db8e043507fe@example.com"],
      participants: [
        %Participant{
          id: "ac3c30e4-e1d5-489f-80f4-671735f444ed",
          nick: "john-eckert",
          jid: "4b2f6c32-fa80-4d97-aeec-db8e043507fe@example.com",
          nodes: @nodes
        },
        %Participant{
          id: "2846ff3f-6b90-48e5-9aad-c3782393d8be",
          nick: "john-mauchly",
          jid: "c3b10914-905d-4920-a5cd-146a0061e478@example.com",
          nodes: @nodes
        }
      ],
      updated_at: ~N[2020-09-23 00:36:20.363444],
      inserted_at: ~N[2020-09-23 00:36:20.363444]
    },
    "c5f74c1b-11e6-4a81-ab6a-afc598180b5a" => %Channel{
      id: "c5f74c1b-11e6-4a81-ab6a-afc598180b5a",
      name: "manchester",
      description: "Manchester University",
      nodes: @nodes,
      contact: nil,
      participants: [
        %Participant{
          id: "c4763641-8a00-4e8e-b6de-aaac712481fa",
          nick: "kathleen-booth",
          jid: "2f540478-fe93-469c-8b9c-7e4ad8fd4339@example.com",
          nodes: @nodes
        },
        %Participant{
          id: "b98dd64f-0f2b-4446-8889-3fc7d3f73113",
          nick: "andrew-booth",
          jid: "f8e744de-3d1b-4528-9cfd-3fa111f7f626@example.com",
          nodes: @nodes
        },
        %Participant{
          id: "3cb92e3e-798b-49c6-a157-2122356e4cea",
          nick: "alain-turing",
          jid: "e784345c-4bed-4ce0-9610-e6f57b9ac6f2@example.com",
          nodes: @nodes
        }
      ],
      updated_at: ~N[2020-09-23 00:36:20.363444],
      inserted_at: ~N[2020-09-23 00:36:20.363444]
    },
    "6535bb5c-732f-4a3b-8329-3923aec636a5" => %Channel{
      id: "6535bb5c-732f-4a3b-8329-3923aec636a5",
      name: "prom 2020",
      description: "online prom!",
      nodes: @nodes,
      contact: nil,
      participants: [
        %Participant{
          id: "07f3022d-cb01-4bd8-8333-0a398be4ee8f",
          nick: "grace-hopper",
          jid: "8852aa0b-b9bd-4427-aa30-9b9b4f1b0ea9@example.com"
        },
        %Participant{
          id: "0d26525e-f3cc-462c-94d1-61a5beafb033",
          nick: "john-von-neumann",
          jid: "c97de5c2-76ed-448d-bff9-ac4f9f32a327@example.com"
        },
        %Participant{
          id: "2365bf25-a61b-4ca2-9fb3-3bee3bb00081",
          nick: "alan-turing",
          jid: "1a2d0b9b-9d10-4e0b-b878-9f8ab581a31f@example.com"
        }
      ],
      updated_at: ~N[2020-10-09 00:45:55.363444],
      inserted_at: ~N[2020-10-09 00:45:55.363444]
    },
    "3cfd82c0-8453-4198-a706-dbec5692dc43" => %Channel{
      id: "3cfd82c0-8453-4198-a706-dbec5692dc43",
      name: "Iceland Friends",
      description: "Friends from Iceland last trip (2021)",
      nodes: @nodes,
      contact: nil,
      owners: ["8852aa0b-b9bd-4427-aa30-9b9b4f1b0ea9@example.com"],
      administrators: ["c97de5c2-76ed-448d-bff9-ac4f9f32a327@example.com"],
      participants: [
        %Participant{
          id: "07f3022d-cb01-4bd8-8333-0a398be4ee8f",
          nick: "grace-hopper",
          jid: "8852aa0b-b9bd-4427-aa30-9b9b4f1b0ea9@example.com"
        },
        %Participant{
          id: "0d26525e-f3cc-462c-94d1-61a5beafb033",
          nick: "john-von-neumann",
          jid: "c97de5c2-76ed-448d-bff9-ac4f9f32a327@example.com"
        }
      ],
      updated_at: ~N[2020-10-09 00:45:55.363444],
      inserted_at: ~N[2020-10-09 00:45:55.363444]
    },
    "28be3cc7-d605-40dd-8b5a-012b59e90c26" => %Channel{
      id: "28be3cc7-d605-40dd-8b5a-012b59e90c26",
      name: "Sweden Friends",
      description: "Friends from Sweden last trip (2020)",
      nodes: @nodes,
      contact: nil,
      owners: ["8852aa0b-b9bd-4427-aa30-9b9b4f1b0ea9@example.com"],
      participants: [
        %Participant{
          id: "07f3022d-cb01-4bd8-8333-0a398be4ee8f",
          nick: "grace-hopper",
          jid: "91d30b13-9905-49a5-8da3-5694b16cff19@example.com"
        },
        %Participant{
          id: "0d26525e-f3cc-462c-94d1-61a5beafb033",
          nick: "john-von-neumann",
          jid: "85c3a29b-7aa8-488f-96a2-41440505f999@example.com"
        }
      ],
      updated_at: ~N[2020-10-09 00:45:55.363444],
      inserted_at: ~N[2020-10-09 00:45:55.363444]
    }
  }

  @impl Channel
  def get(id) do
    @data[id]
  end

  @impl Channel
  def list_by_jid(jid) do
    Enum.filter(@data, fn {_, channel} ->
      jid in channel.owners or
        jid in channel.administrators or
        Enum.any?(channel.participants, &(&1.jid == jid))
    end)
    |> Enum.map(fn {_, channel} -> channel end)
  end

  def config_params(_channel) do
    %{
      "Messages Node Subscription" => "allowed",
      "No Private Messages" => "true",
      {"ENV", "hidden"} => "test"
    }
  end

  def info_params(channel) do
    %{
      "Created At" => to_string(channel.inserted_at)
    }
  end

  def join(_channel, "forbid@example.com", _nick, _nodes) do
    {:error, :forbidden}
  end

  def join(_channel, "missing@example.com", _nick, _nodes) do
    {:error, :not_implemented}
  end

  def join(_channel, "unknown@example.com", _nick, _nodes) do
    {:error, :unknown}
  end

  def join(%Channel{id: "6535bb5c-732f-4a3b-8329-3923aec636a5"}, jid, nick, nodes) do
    intersect_nodes = Enum.sort(nodes -- nodes -- @nodes)
    participant = Participant.new("92cd9729-7755-4d41-a09b-7105c005aae2", jid, nick, nodes)
    {:ok, {participant, intersect_nodes}}
  end

  def update_nodes(_channel, "c97de5c2-76ed-448d-bff9-ac4f9f32a327@example.com", _add_nodes, _rem_nodes) do
    {:error, :unknown}
  end

  def update_nodes(_channel, "1a2d0b9b-9d10-4e0b-b878-9f8ab581a31f@example.com", _add_nodes, _rem_nodes) do
    {:error, :not_implemented}
  end

  def update_nodes(%Channel{nodes: nodes}, _user_id, add_nodes, rem_nodes) do
    nodes = add_nodes ++ (nodes -- rem_nodes)
    {:ok, %Channel{nodes: nodes}}
  end

  def leave(_channel, "2f540478-fe93-469c-8b9c-7e4ad8fd4339@example.com") do
    {:error, :noimpl}
  end

  def leave(%Channel{} = channel, user_jid) do
    if Channel.is_participant?(channel, user_jid) do
      :ok
    else
      {:error, :notfound}
    end
  end

  def set_nick(%Channel{} = channel, user_jid, nick) do
    if Channel.is_participant?(channel, user_jid) do
      case nick do
        "duplicated" -> {:error, :conflict}
        "error" -> {:error, :unknown}
        _ -> :ok
      end
    else
      {:error, :forbidden}
    end
  end

  def store_message(%Channel{}, %Xmlel{attrs: %{"id" => "error"}}) do
    {:error, :invalid_message}
  end

  def store_message(%Channel{}, %Xmlel{attrs: %{"id" => "disable-store"}}) do
    {:ok, nil}
  end

  def store_message(%Channel{}, %Xmlel{}) do
    {:ok, "6c015cac-ca8e-44d1-9b6d-b719f76edfaf"}
  end

  def create(_id, "fail@example.com") do
    {:error, :invalid}
  end

  def create(id, user_jid) do
    {:ok, %Channel{id: id, owners: [user_jid]}}
  end

  def update(channel, params, "urn:xmpp:mix:nodes:info") do
    {:ok,
      %Channel{channel |
        name: params["name"] || channel.name,
        description: params["description"] || channel.description
      }
    }
  end

  def update(_channel, _params, _node) do
    {:error, :invalid}
  end

  def destroy(%Channel{owners: owners}, user_jid) do
    if user_jid in owners do
      :ok
    else
      {:error, :forbidden}
    end
  end
end
