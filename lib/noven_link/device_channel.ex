defmodule NovenLink.DeviceChannel do
  alias PhoenixClient.Channel
  require Logger

  defmodule State do
    defstruct params: %{},
              socket: NovenLink.Socket,
              topic: nil,
              connected?: false,
              channel: nil,
              rejoin_after: 5000,
              livestream: nil,
              host: nil,
              port: nil
  end

  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def terminate(reason, state) do
    Logger.info("Stopping livestream")

    if state.livestream && Process.alive?(state.livestream),
      do: Process.exit(state.livestream, reason)
  end

  def init(opts) do
    send(self(), :join)
    rejoin_after = Application.get_env(:noven_link, :rejoin_after, 5_000)
    uuid = System.unique_integer([:positive])

    {:ok,
     %State{
       params: opts[:params],
       socket: opts[:socket],
       topic: "device:#{uuid}",
       connected?: false,
       rejoin_after: rejoin_after,
       host: nil,
       port: nil
     }}
  end

  def handle_info(:join, %{socket: socket, topic: topic, params: params} = state) do
    case Channel.join(socket, topic, params) do
      {:ok, %{"host" => host, "port" => port}, channel} ->
        Logger.info("Joined channel")
        Process.send_after(self(), :checkup, 5000)
        {:noreply, %{state | channel: channel, connected?: true, host: host, port: port}}

      _error ->
        Process.send_after(self(), :join, state.rejoin_after)
        {:noreply, %{state | connected?: false}}
    end
  end

  def handle_info(:checkup, state) do
    if PhoenixClient.Socket.connected?(state.socket) do
      Process.send_after(self(), :checkup, 5000)
      {:noreply, state}
    else
      {:stop, :socket_disconnect, state}
    end
  end

  def handle_info(
        %PhoenixClient.Message{
          event: "play",
          payload: _
        },
        state
      ) do
    Logger.info "Starting Livestream"
    {:ok, livestream} = NovenLink.LiveStream.start_link(state.host, state.port)
    {:noreply, %{state | livestream: livestream}}
  end

  def handle_info(
        %PhoenixClient.Message{
          event: "stop",
          payload: _
        },
        state
      ) do
    Logger.info "Stopping livestream"
    state.livestream && GenServer.stop(state.livestream, :normal)
    {:noreply, %{state | livestream: nil}}
  end
end
