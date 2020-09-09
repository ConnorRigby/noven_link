defmodule NovenLink.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  alias NovenLink.{
    Socket,
    DeviceChannel
  }

  def start(_type, _args) do
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: NovenLink.Supervisor]
    children =
      [
        # Children for all targets
        # Starts a worker by calling: NovenLink.Worker.start_link(arg)
        # {NovenLink.Worker, arg},
      ] ++ children(target())

    Supervisor.start_link(children, opts)
  end

  # List all child processes to be supervised
  def children(:host) do
    config = [
      socket: [
        url: "ws://localhost:4000/device_socket/websocket?token=a88gdF7lsFlCA4D2fxf5q3HgPNWaeaEXc2TwmOkZiFA"
        # url: "wss://noven.app/device_socket/websocket?token=owH7dbUjU7AWcO3WBbeW7sYHJ77kZ6hF9IhO2zlyX3c"
      ]
    ]

    [
      {PhoenixClient.Socket, {config[:socket], [name: Socket]}},
      {DeviceChannel, [socket: Socket, params: config[:params]]},
      # Children that only run on the host
      # Starts a worker by calling: NovenLink.Worker.start_link(arg)
      # {NovenLink.Worker, arg},
    ]
  end

  def children(_target) do
    # VintageNetWizard.run_wizard()
    url = Nerves.Runtime.KV.get("noven_url")
    Nerves.Runtime.validate_firmware()
    [
      {PhoenixClient.Socket, {[url: url], [name: Socket]}},
      {DeviceChannel, [socket: Socket]},
      # Children for all targets except host
      # Starts a worker by calling: NovenLink.Worker.start_link(arg)
      # {NovenLink.Worker, arg},
    ]
  end

  def target() do
    Application.get_env(:noven_link, :target)
  end
end
