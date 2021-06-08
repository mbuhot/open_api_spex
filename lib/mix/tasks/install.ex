defmodule Mix.Tasks.Openapi.Spec.Install do
  @moduledoc """
  Fetch and install the resources locally for the interface.

    ## Example

      mix run Openapi.Install '/path_to_app'
  """
  use Mix.Task

  @preset 'https://cdnjs.cloudflare.com/ajax/libs/swagger-ui/3.32.4/swagger-ui-standalone-preset.js'
  @css 'https://cdnjs.cloudflare.com/ajax/libs/swagger-ui/3.32.4/swagger-ui.css'
  @bundle 'https://cdnjs.cloudflare.com/ajax/libs/swagger-ui/3.32.4/swagger-ui-bundle.js'

  @impl true
  def run([path]) do
    Mix.Task.run("app.start")

    :inets.start()
    :ssl.start()

    {:ok, :saved_to_file} = :httpc.request(:get, {css, []}, [], [stream: path <> '/css/'])
    {:ok, :saved_to_file} = :httpc.request(:get, {@preset, []}, [], [stream: path <> '/js/'])
    {:ok, :saved_to_file} = :httpc.request(:get, {@bundle, []}, [], [stream: path <> '/js/'])

  end


  end