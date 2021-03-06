defmodule Mixite.Xmpp.ErrorController do
  use Exampple.Component
  require Logger

  def send_error(conn, {_type, _lang, _text} = error) do
    conn
    |> error(error)
    |> send()
  end

  def send_not_found(conn, lang \\ "en", text \\ "channel not found") do
    conn
    |> error({"item-not-found", lang, text})
    |> send()
  end

  def send_forbidden(conn, lang \\ "en", text \\ "forbidden access to channel") do
    conn
    |> error({"forbidden", lang, text})
    |> send()
  end

  def send_conflict(conn, lang \\ "en", text \\ "element exists") do
    conn
    |> error({"conflict", lang, text})
    |> send()
  end

  def send_feature_not_implemented(conn, lang \\ "en", text) do
    conn
    |> error({"feature-not-implemented", lang, text})
    |> send()
  end

  def send_internal_error(conn, lang \\ "en", text \\ "an internal error happened") do
    conn
    |> error({"internal-server-error", lang, text})
    |> send()
  end

  def send_bad_request(conn, lang \\ "en", text \\ "wrong request for query") do
    conn
    |> error({"bad-request", lang, text})
    |> send()
  end

  def handle_error(%{type: "result"}, _query), do: :ignore
  def handle_error(%{type: "error"}, _query), do: :ignore
  def handle_error(%{stanza_type: "message"}, _query), do: :ignore
  def handle_error(%{stanza_type: "presence"}, _query), do: :ignore

  def handle_error(conn, _query) do
    Logger.error("not valid namespace: #{inspect(conn.xmlns)} for #{inspect(conn.stanza_type)}")
    send_feature_not_implemented(conn, "invalid namespace #{conn.xmlns}")
  end
end
