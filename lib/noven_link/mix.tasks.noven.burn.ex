defmodule Mix.Tasks.NovenLink.Burn do
  use Mix.Task

  def run([identifier, token]) do
    System.put_env("NOVEN_TOKEN", token)
    Mix.Task.run("nerves_hub.device", ["burn", identifier])
  end
end
