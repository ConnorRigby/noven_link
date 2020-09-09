defmodule NovenLink.LiveStream do
  use GenServer
  require Logger

  def start_link(host, port) do
    GenServer.start_link(__MODULE__, [host, port], name: __MODULE__)
  end

  @impl GenServer
  def terminate(_reason, state) do
    IO.puts "Livestream terminate: #{inspect(state.gst)}"
    if state.gst, do: Process.exit(state.gst, :shutdown)
  end

  @impl GenServer
  def init([host, port]) do
    send(self(), :start_stream)
    {:ok, %{host: to_charlist(host), port: port, gst: nil}}
  end

  @impl GenServer
  def handle_info(:start_stream, state) do
    Logger.info "Connecting to socket: #{state.host} #{state.port}"
    gst = start_gst(state.host, state.port)
    Process.link(gst)
    {:noreply, %{state | gst: gst}}
  end

  defp start_gst(host, port) do
    gst = System.find_executable("gst-launch-1.0")

    args = [
      "v4l2src",
      "!",
      "video/x-h264,",
      "stream-format=byte-stream,",
      "alignment=au,",
      "width=640,",
      "height=480,",
      "pixel-aspect-ratio=1/1,",
      "framerate=30/1",
      "!",
      "rtph264pay",
      "pt=96",
      "!",
      # "fdsink",
      # "fd=4",
      "udpsink",
      "host=#{host}",
      "port=#{port}"
    ]

    # :erlang.open_port({:spawn_executable, gst}, [
    #   {:args, args},
    #   :binary,
    #   :nouse_stdio,
    #   :exit_status
    # ])
    spawn(fn -> MuonTrap.cmd(gst, args, into: IO.stream(:stdio, :line)) end)
  end
end
