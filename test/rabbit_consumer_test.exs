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

defmodule RabbitConsumerTest do
  use ExUnit.Case
  doctest RabbitConsumer

  test "can run my_consumer" do
    MyConsumer.start_link([])
  end
end
