defmodule Mixite.Xmpp.ErrorController do
  use Exampple.Component
  require Logger

  def send_not_found(conn) do
    conn
    |> iq_error({"item-not-found", "en", "channel not found"})
    |> send()
  end

  def send_forbidden(conn) do
    conn
    |> iq_error({"forbidden", "en", "forbidden access to channel"})
    |> send()
  end

  def error(%{type: "error"}, _query), do: :ignore
  def error(%{stanza_type: "message"}, _query), do: :ignore
  def error(%{stanza_type: "presence"}, _query), do: :ignore

  def error(conn, _query) do
    Logger.error("not valid namespace: #{inspect(conn.xmlns)} for #{inspect(conn.stanza_type)}")

    conn
    |> iq_error("feature-not-implemented")
    |> send()
  end
end
