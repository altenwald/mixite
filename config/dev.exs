import Config

config :mixite, Exampple.Component,
  domain: "mixite.example.com",
  host: "localhost",
  password: "guest",
  ping: 30_000,
  port: 5252,
  set_from: false,
  trimmed: true,
  auto_connect: 500
