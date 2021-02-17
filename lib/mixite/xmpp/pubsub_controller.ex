defmodule Mixite.Xmpp.PubsubController do
  use Exampple.Component
  use Mixite.Namespaces

  require Logger

  import Mixite.Xmpp.ErrorController,
    only: [
      send_not_found: 1,
      send_forbidden: 1,
      send_error: 2
    ]

  alias Exampple.Xml.Xmlel
  alias Exampple.Xmpp.Jid
  alias Mixite.{Broadcast, Channel, Pubsub}

  def get(conn, [%Xmlel{children: [%Xmlel{attrs: %{"node" => node}}]}]) do
    channel_id = if conn.to_jid.node != "", do: conn.to_jid.node
    from_jid = Jid.to_bare(conn.from_jid)
    proc_get_node = &Pubsub.process_get_node/3
    process_get_result(conn, channel_id, from_jid, node, proc_get_node)
  end

  defp process_get_result(conn, channel_id, from_jid, node, proc_get_node) do
    case proc_get_node.(channel_id, from_jid, node) do
      :ignore ->
        process_get_result(conn, channel_id, from_jid, node, &process_get_node/3)

      nil ->
        send_not_found(conn)

      :forbidden ->
        send_forbidden(conn)

      {:error, error} ->
        send_error(conn, error)

      {:ok, %Xmlel{} = item} ->
        conn
        |> iq_resp([Pubsub.wrapper(:result_get, node, [item])])
        |> send()

      {:ok, [%Xmlel{} | _] = items} ->
        conn
        |> iq_resp([Pubsub.wrapper(:result_get, node, items)])
        |> send()
    end
  end

  def set(conn, [%Xmlel{children: [%Xmlel{attrs: %{"node" => node}} = query]}]) do
    channel_id = if conn.to_jid.node != "", do: conn.to_jid.node
    from_jid = Jid.to_bare(conn.from_jid)
    mix_jid = Jid.to_bare(conn.to_jid)
    proc_set_node = &Pubsub.process_set_node/4
    process_set_result(conn, channel_id, from_jid, mix_jid, node, query, proc_set_node)
  end

  defp process_set_result(conn, channel_id, from_jid, mix_jid, node, query, proc_set_node) do
    case proc_set_node.(channel_id, from_jid, node, query) do
      :ignore ->
        process_set_result(conn, channel_id, from_jid, mix_jid, node, query, &process_set_node/4)

      nil ->
        send_not_found(conn)

      :forbidden ->
        send_forbidden(conn)

      {:error, error} ->
        send_error(conn, error)

      {:ok, channel, %Xmlel{} = item} ->
        conn
        |> iq_resp([Pubsub.wrapper(:result_set, node, [item])])
        |> send()

        Broadcast.send(channel, [Pubsub.wrapper(:event, node, [item])], mix_jid, extra: true)

      {:ok, channel, [%Xmlel{} | _] = items} ->
        conn
        |> iq_resp([Pubsub.wrapper(:result_set, node, items)])
        |> send()

        Broadcast.send(channel, [Pubsub.wrapper(:event, node, items)], mix_jid, extra: true)
    end
  end

  def process_get_node(channel_id, from_jid, @ns_config) when channel_id != "" do
    with channel = %Channel{} <- Channel.get(channel_id),
         true <- Channel.can_view?(channel, from_jid) do
      {:ok, Pubsub.render(channel, @ns_config)}
    else
      nil -> nil
      false -> :forbidden
    end
  end

  def process_get_node(channel_id, from_jid, @ns_info) when channel_id != "" do
    with channel = %Channel{} <- Channel.get(channel_id),
         true <- Channel.can_view?(channel, from_jid) do
      {:ok, Pubsub.render(channel, @ns_info)}
    else
      nil -> nil
      false -> :forbidden
    end
  end

  def process_get_node(channel_id, from_jid, node)
      when channel_id != "" and node in [@ns_participants, @ns_allowed, @ns_banned] do
    with channel = %Channel{} <- Channel.get(channel_id),
         true <- Channel.can_view?(channel, from_jid) do
      {:ok, Pubsub.render(channel, node)}
    else
      nil -> nil
      false -> :forbidden
    end
  end

  def process_get_node(_channel_id, _from_jid, nodes) do
    {:error, {"feature-not-implemented", "en", "#{nodes} not implemented"}}
  end

  def process_set_node(channel_id, from_jid, @ns_config, query) when channel_id != "" do
    with channel = %Channel{} <- Channel.get(channel_id),
         {:ok, config} <- Pubsub.process_config(query) do
      case Channel.update(channel, from_jid, config, @ns_config) do
        {:ok, channel} ->
          {:ok, channel, Pubsub.render(channel, @ns_config)}

        {:error, :forbidden} ->
          :forbidden

        {:error, error} ->
          Logger.error("cannot update config channel: #{inspect(error)}")
          {:error, error}
      end
    else
      nil ->
        nil

      {:error, error} ->
        Logger.error("cannot update config channel: #{inspect(error)}")
        {:error, error}
    end
  end

  def process_set_node(channel_id, from_jid, @ns_info, query) when channel_id != "" do
    with channel = %Channel{} <- Channel.get(channel_id),
         {:ok, info} <- Pubsub.process_info(query) do
      case Channel.update(channel, from_jid, info, @ns_info) do
        {:ok, channel} ->
          {:ok, channel, Pubsub.render(channel, @ns_info)}

        {:error, :forbidden} ->
          :forbidden

        {:error, error} ->
          Logger.error("cannot update info channel: #{inspect(error)}")
          {:error, {"internal-server-error", "en", "An error happened"}}
      end
    else
      nil ->
        nil

      {:error, error} ->
        Logger.error("cannot update info channel: #{inspect(error)}")
        {:error, {"internal-server-error", "en", "An error happened"}}
    end
  end

  def process_set_node(channel_id, from_jid, node, query)
      when channel_id != "" and node in [@ns_allowed, @ns_banned] do
    with channel = %Channel{} <- Channel.get(channel_id),
         {:ok, info} <- Pubsub.process_participants(query) do
      case Channel.update(channel, from_jid, info, node) do
        {:ok, channel, _action, _jids} ->
          {:ok, channel, Pubsub.render(channel, node)}

        {:error, :forbidden} ->
          :forbidden

        {:error, error} ->
          Logger.error("cannot update info channel: #{inspect(error)}")
          {:error, {"internal-server-error", "en", "An error happened"}}
      end
    else
      nil ->
        nil

      {:error, error} ->
        Logger.error("cannot update info channel: #{inspect(error)}")
        {:error, {"internal-server-error", "en", "An error happened"}}
    end
  end

  def process_set_node(channel_id, _from_jid, nodes, query) do
    Logger.warn("#{inspect(channel_id)} - #{inspect(nodes)}: #{inspect(query)}")
    {:error, {"feature-not-implemented", "en", "#{nodes} not implemented"}}
  end
end
