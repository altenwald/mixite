import Config

config :mixite,
  router: Mixite.Router

config :logger, :console,
  format: "$date $time $metadata[$level] $levelpad$message\n",
  metadata: [:ellapsed_time, :stanza_id, :stanza_type, :type]

import_config "#{Mix.env()}.exs"
