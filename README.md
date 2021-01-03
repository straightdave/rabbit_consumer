# RabbitConsumer

RabbitConsumer is a mixin which transforms your modules into RabbitMQ consumers.

## Get started

Define a module with the mixin:
```elixir
defmodule MyConsumer do
  use RabbitConsumer,
    host: "192.168.99.100",
    exchange: "ex1",
    queue: "q1"

  def process(payload, _meta) do
    case payload do
      "stop" -> :stop
      _ -> IO.puts("payload=#{inspect(payload)}")
    end
  end
end
```

You can provide following arguments to _use_ the mixin:
* __host__: The host of RabbitMQ server, `"localhost"` by default.
* __port__: The port of RabbitMQ server, `5672` by default.
* __process_fn__: The name of processing function, `:process` by default.
* __exchange__: The name of the exchange to follow, `""` by default.
* __exchange_type__: The type of the exchange to follow, `:direct` by default.
* __queue__: The name of the queue to read, `""` by default.
* __queue_opts__: The options to declare the queue, `[]` by default.
* __binding_keys__: The binding_keys (strings) to bind with the exchange, `[]` by default.

> For `:fanout` exchanges, you may need to bind your queue to the exchanges. To do so, you can provide a dummy binding_keym like `[""]`. A _fanout_ exchange would ignore that key but just get bound.

### Message processing function

There're two parameters for your processing function. In order they are:
* __payload__: message body, normally a string.
* __meta__: message meta, provided by AMQP for each message.

No matter in which name you call your processing function, the two parameters are given in this order.

### Start your consumer

In an application with a supervisor, you can register your consumer module as one normal GenServer:
```elixir
children = [
  MyConsumer,
]

opts = [strategy: :one_for_one, name: Classifier.Supervisor]
Supervisor.start_link(children, opts)
```

Or, start it manually, say, in an IEx session:
```
iex(1)> MyConsumer.start_link([])
```

As soon as your consumer starts, it connects to the queue and keeps listening and processing.

### Stop your consumer

In your processing function, if the function returns `:stop` atom, the whole listen-and-process loop would stop. Then the `on_ending()` callback would be invoked to do some clean-up:
```elixir
def process(payload, _meta) do
  case payload do
    "stop" -> :stop # <= like this
    _ -> IO.puts("payload=#{inspect(payload)}")
  end 
end
```

### Callbacks

There're two callbacks `on_ready()` and `on_ending()`. `on_ready()` is called right after the MQ connection is established, before the listen-and-process loop starts. `on_ending()`, as mentioned above, is called after listen-and-process loop ends. If not overrided, they print some information.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `rabbit_consumer` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:rabbit_consumer, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/rabbit_consumer](https://hexdocs.pm/rabbit_consumer).

