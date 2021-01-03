defmodule RabbitConsumer do
  @moduledoc """
  Splendid RabbitMQ Consumer Mixin
  """

  defmacro __using__(args) do
    host = Keyword.get(args, :host, "localhost")
    port = Keyword.get(args, :port, 5672)
    proc_fn = Keyword.get(args, :process_fn, :process)
    ex = Keyword.get(args, :exchange, "")
    ex_type = Keyword.get(args, :exchange_type, :direct)
    q = Keyword.get(args, :queue, "")
    q_opts = Keyword.get(args, :queue_opts, [])
    binding_keys = Keyword.get(args, :binding_keys, [])

    quote do
      @me __MODULE__

      @host unquote(host)
      @port unquote(port)
      @proc_fn unquote(proc_fn)
      @ex unquote(ex)
      @ex_type unquote(ex_type)
      @q unquote(q)
      @q_opts unquote(q_opts)
      @binding_keys unquote(binding_keys)

      use GenServer

      def on_ready(), do: IO.puts("#{@me} as RabbitConsumer is ready.")
      def on_ending(), do: IO.puts("#{@me} as RabbitConsumer is leaving.")
      defoverridable(on_ready: 0, on_ending: 0)

      def start_link(opts) do
        opts = Keyword.put(opts, :name, @me)
        GenServer.start_link(@me, [], opts)
      end

      @impl GenServer
      def init(_) do
        case AMQP.Connection.open(host: @host, port: @port) do
          {:ok, conn} ->
            {:ok, chan} = AMQP.Channel.open(conn)
            AMQP.Exchange.declare(chan, @ex, @ex_type)
            {:ok, %{queue: queue_name}} = AMQP.Queue.declare(chan, @q, @q_opts)

            for binding_key <- @binding_keys do
              AMQP.Queue.bind(chan, queue_name, @ex, routing_key: binding_key)
            end

            AMQP.Basic.consume(chan, queue_name, nil, no_ack: true)
            apply(@me, :on_ready, [])
            wait_for_msg()
            apply(@me, :on_ending, [])
            AMQP.Connection.close(conn)
            {:ok, []}

          {:error, reason} ->
            IO.puts("Failed to connect to Rabbit: #{reason}")
            {:stop, reason}

          _ ->
            {:stop, "Unknown Error"}
        end
      end

      defp wait_for_msg() do
        receive do
          {_deliver, payload, meta} ->
            case apply(@me, @proc_fn, [payload, meta]) do
              :stop ->
                IO.puts("stopped")
                nil

              any ->
                IO.puts("#{inspect(any)}")
                wait_for_msg()
            end

          any ->
            IO.puts("non-deliver msg from Rabbit: #{inspect(any)}")
            wait_for_msg()
        end
      end
    end
  end
end
