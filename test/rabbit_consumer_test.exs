defmodule MyConsumer do
  use RabbitConsumer

  def on_ready() do
    IO.puts("I am ready")
  end

  def on_ending() do
    IO.puts("I am leaving")
  end

  def process(payload: payload, meta: _meta) do
    IO.puts("payload=#{payload}")
  end
end

defmodule RabbitConsumerTest do
  use ExUnit.Case
  doctest RabbitConsumer

  test "one equals one" do
    assert 1 == 1
  end
end
