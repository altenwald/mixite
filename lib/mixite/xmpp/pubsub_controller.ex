defmodule Mixite.Xmpp.PubsubController do
  use Exampple.Component

  require Logger

  import Mixite.Xmpp.ErrorController,
    only: [
      send_not_found: 1,
      send_forbidden: 1,
      send_error: 2
    ]

  alias Exampple.Router.Conn
  alias Exampple.Xml.Xmlel
  alias Exampple.Xmpp.Jid
  alias Mixite.{Broadcast, Channel, Pubsub}

  @ns_config "urn:xmpp:mix:nodes:config"
  @ns_info "urn:xmpp:mix:nodes:info"
  @ns_participants "urn:xmpp:mix:nodes:participants"

  def get(conn, [%Xmlel{children: [%Xmlel{attrs: %{"node" => node}}]}]) do
    channel_id = if conn.to_jid.node != "", do: conn.to_jid.node
    from_jid = Jid.to_bare(conn.from_jid)

    case Pubsub.process_get_node(channel_id, from_jid, node) do
      :ignore ->
        case process_get_node(conn, node) do
          nil ->
            send_not_found(conn)

          :forbidden ->
            send_forbidden(conn)

          {:error, error} ->
            send_error(conn, error)

          {:ok, %Xmlel{} = item} ->
            conn
            |> iq_resp([Pubsub.wrapper(:pubsub, node, [item])])
            |> send()

          {:ok, [%Xmlel{} | _] = items} ->
            conn
            |> iq_resp([Pubsub.wrapper(:pubsub, node, items)])
            |> send()
        end

      {:error, error} ->
        send_error(conn, error)

      {:ok, %Xmlel{} = item} ->
        conn
        |> iq_resp([Pubsub.wrapper(:pubsub, node, [item])])
        |> send()

      {:ok, [%Xmlel{} | _] = items} ->
        conn
        |> iq_resp([Pubsub.wrapper(:pubsub, node, items)])
        |> send()
    end
  end

  def set(conn, [%Xmlel{children: [%Xmlel{attrs: %{"node" => node}} = query]}]) do
    channel_id = if conn.to_jid.node != "", do: conn.to_jid.node
    from_jid = Jid.to_bare(conn.from_jid)
    mix_jid = Jid.to_bare(conn.to_jid)

    case Pubsub.process_set_node(channel_id, from_jid, node, query) do
      :ignore ->
        case process_set_node(conn, node, query) do
          nil ->
            send_not_found(conn)

          :forbidden ->
            send_forbidden(conn)

          {:error, error} ->
            send_error(conn, error)

          {:ok, channel, %Xmlel{} = item} ->
            conn
            |> iq_resp([Pubsub.wrapper(:pubsub, node, [item])])
            |> send()

            Broadcast.send(channel, [Pubsub.wrapper(:event, node, [item])], mix_jid)

          {:ok, channel, [%Xmlel{} | _] = items} ->
            conn
            |> iq_resp([Pubsub.wrapper(:pubsub, node, items)])
            |> send()

            Broadcast.send(channel, [Pubsub.wrapper(:event, node, items)], mix_jid)
        end

      {:error, error} ->
        send_error(conn, error)

      {:ok, channel, %Xmlel{} = item} ->
        conn
        |> iq_resp([Pubsub.wrapper(:pubsub, node, [item])])
        |> send()

        Broadcast.send(channel, [Pubsub.wrapper(:event, node, [item])], mix_jid)

      {:ok, channel, [%Xmlel{} | _] = items} ->
        conn
        |> iq_resp([Pubsub.wrapper(:pubsub, node, items)])
        |> send()

        Broadcast.send(channel, [Pubsub.wrapper(:event, node, items)], mix_jid)
    end
  end

  def process_get_node(%Conn{to_jid: %Jid{node: channel_id}} = conn, @ns_config)
      when channel_id != "" do
    from_jid = Jid.to_bare(conn.from_jid)

    with channel = %Channel{} <- Channel.get(channel_id),
         true <- Channel.can_view?(channel, from_jid) do
      {:ok, Pubsub.render(channel, @ns_config)}
    else
      nil -> nil
      false -> :forbidden
    end
  end

  def process_get_node(%Conn{to_jid: %Jid{node: channel_id}} = conn, @ns_info)
      when channel_id != "" do
    from_jid = Jid.to_bare(conn.from_jid)

    with channel = %Channel{} <- Channel.get(channel_id),
         true <- Channel.can_view?(channel, from_jid) do
      {:ok, Pubsub.render(channel, @ns_info)}
    else
      nil -> nil
      false -> :forbidden
    end
  end

  def process_get_node(
        %Conn{to_jid: %Jid{node: channel_id}} = conn,
        @ns_participants
      )
      when channel_id != "" do
    from_jid = Jid.to_bare(conn.from_jid)

    with channel = %Channel{} <- Channel.get(channel_id),
         true <- Channel.can_view?(channel, from_jid) do
      {:ok, Pubsub.render(channel, @ns_participants)}
    else
      nil -> nil
      false -> :forbidden
    end
  end

  def process_get_node(_conn, nodes) do
    {:error, {"feature-not-implemented", "en", "#{nodes} not implemented"}}
  end

  def process_set_node(%Conn{to_jid: %Jid{node: channel_id}} = conn, @ns_config, query)
      when channel_id != "" do
    from_jid = Jid.to_bare(conn.from_jid)

    with channel = %Channel{} <- Channel.get(channel_id),
         {:ok, config} <- Pubsub.process_config(query),
         true <- Channel.can_modify?(channel, from_jid) do
      case Channel.update(channel, config, @ns_config) do
        {:ok, channel} ->
          {:ok, channel, Pubsub.render(channel, @ns_config)}

        {:error, error} ->
          Logger.error("cannot update config channel: #{inspect(error)}")
          {:error, error}
      end
    else
      nil -> nil
      false -> :forbidden
      {:error, error} ->
        Logger.error("cannot update config channel: #{inspect(error)}")
        {:error, error}
    end
  end

  def process_set_node(%Conn{to_jid: %Jid{node: channel_id}} = conn, @ns_info, query)
      when channel_id != "" do
    from_jid = Jid.to_bare(conn.from_jid)

    with channel = %Channel{} <- Channel.get(channel_id),
         {:ok, info} <- Pubsub.process_info(query),
         true <- Channel.can_modify?(channel, from_jid) do
      case Channel.update(channel, info, @ns_info) do
        {:ok, channel} ->
          {:ok, channel, Pubsub.render(channel, @ns_info)}

          {:error, error} ->
            Logger.error("cannot update info channel: #{inspect(error)}")
            {:error, {"internal-server-error", "en", "An error happened"}}
      end
    else
      nil -> nil
      false -> :forbidden
      {:error, error} ->
        Logger.error("cannot update info channel: #{inspect(error)}")
        {:error, {"internal-server-error", "en", "An error happened"}}
    end
  end

  def process_set_node(_conn, nodes) do
    {:error, {"feature-not-implemented", "en", "#{nodes} not implemented"}}
  end
end
