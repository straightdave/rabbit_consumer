defmodule RabbitConsumer do
  @moduledoc """
  Splendid Rabbit Consumer
  """

  defmacro __using__(args) do
    addr = Keyword.get(args, :address, "localhost:5672")
    proc_fn = Keyword.get(args, :process_fn, :process)
    ex = Keyword.get(args, :exchange, "")
    ex_type = Keyword.get(args, :exchange_type, :direct)
    q = Keyword.get(args, :queue_name, "")
    q_opts = Keyword.get(args, :queue_opts, [])
    binding_keys = Keyword.get(args, :binding_keys, [])

    quote do
      @me __MODULE__

      @addr unquote(addr)
      @proc_fn unquote(proc_fn)
      @ex unquote(ex)
      @ex_type unquote(ex_type)
      @q unquote(q)
      @q_opts unquote(q_opts)
      @binding_keys unquote(binding_keys)

      use GenServer

      def on_ready() do
      end

      def on_ending() do
      end

      defp wait_for_msg() do
        receive do
          {_deliver, payload, meta} ->
            apply(@me, @proc_fn, payload: payload, meta: meta)
            wait_for_msg()
        end
      end

      def start_link(opts) do
        opts = Keyword.put(opts, :name, @me)
        GenServer.start_link(@me, [], opts)
      end

      @impl GenServer
      def init(_) do
        {:ok, conn} = AMQP.Connection.open(host: @addr)
        {:ok, chan} = AMQP.Channel.open(conn)
        AMQP.Exchange.declare(chan, @ex, @ex_type)
        {:ok, %{queue: queue_name}} = AMQP.Queue.declare(chan, @q, @q_opts)

        for binding_key <- @binding_keys do
          AMQP.Queue.bind(chan, queue_name, @ex, routing_key: binding_key)
        end

        AMQP.Basic.consume(chan, queue_name, nil, no_ack: true)

        apply(@me, :on_ready)
        wait_for_msg()
        apply(@me, :on_ending)

        AMQP.Connection.close(conn)
        {:ok, []}
      end

      @impl GenServer
      def handle_info(call, msg) do
        {:noreply, []}
      end
    end
  end
end