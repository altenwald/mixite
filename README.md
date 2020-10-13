# MIXite

[XEP-0313]: https://xmpp.org/extensions/xep-0313.html
[XEP-0359]: https://xmpp.org/extensions/xep-0359.html
[XEP-0369]: https://xmpp.org/extensions/xep-0369.html
[XEP-0406]: https://xmpp.org/extensions/xep-0406.html

MIXite is an generic implementation of [MIX][XEP-0369] which uses also the [Stanza ID][XEP-0359] implementation and [MAM][XEP-0313] for message storing and querying.

## Standards

The development of Mixite follows the following standards:

- [`Stanza ID`][XEP-0359]: Unique and Stable Stanza IDs.
- [`MIX`][XEP-0369]: Meditated Information eXchange.
- [`MIX-ADMIN`][XEP-0406]: MIX Administration (roles and administrative operations).
- [`MAM`][XEP-0313]: Message Archive Management.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `mixite` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:mixite, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/mixite](https://hexdocs.pm/mixite).
