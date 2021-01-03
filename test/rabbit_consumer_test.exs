defmodule MyConsumer do
  use RabbitConsumer,
    host: "192.168.99.100",
    exchange: "ex3",
    exchange_type: :fanout,
    binding_keys: ["any"]

  def process(payload, meta) do
    case payload do
      "stop" -> :stop
      _ -> IO.puts("payload=#{inspect(payload)}, meta=#{inspect(meta)}")
    end
  end
end

defmodule RabbitConsumerTest do
  use ExUnit.Case
  doctest RabbitConsumer

  test "can run my_consumer" do
    MyConsumer.start_link([])
  end
end
