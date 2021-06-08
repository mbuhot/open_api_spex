defmodule OpenApiSpex.Plug.SwaggerUI.Local do
  @moduledoc """
  Module plug that serves SwaggerUI.

  The full path to the API spec must be given as a plug option.
  The API spec should be served at the given path, see `OpenApiSpex.Plug.RenderSpec`

  ## Configuring SwaggerUI

  SwaggerUI can be configured through plug `opts`.
  All options will be converted from `snake_case` to `camelCase` and forwarded to the `SwaggerUIBundle` constructor.
  See the [swagger-ui configuration docs](https://swagger.io/docs/open-source-tools/swagger-ui/usage/configuration/) for details.
  Should dynamic configuration be required, the `config_url` option can be set to an API endpoint that will provide additional config.

  ## Example

      scope "/" do
        pipe_through :browser # Use the default browser stack

        get "/", MyAppWeb.PageController, :index
        get "/swaggerui", OpenApiSpex.Plug.SwaggerUI,
          path: "/api/openapi",
          default_model_expand_depth: 3,
          display_operation_id: true
      end

      # Other scopes may use custom stacks.
      scope "/api" do
        pipe_through :api
        resources "/users", MyAppWeb.UserController, only: [:index, :create, :show]
        get "/openapi", OpenApiSpex.Plug.RenderSpec, :show
      end
  """
  @behaviour Plug

  @html """
  <!-- HTML for static distribution bundle build -->
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <title>Swagger UI</title>
      <link rel="stylesheet" type="text/css" href="/css/swagger-ui.css" >
      <link rel="icon" type="image/png" href="./favicon-32x32.png" sizes="32x32" />
      <link rel="icon" type="image/png" href="./favicon-16x16.png" sizes="16x16" />
      <style>
        html
        {
          box-sizing: border-box;
          overflow: -moz-scrollbars-vertical;
          overflow-y: scroll;
        }
        *,
        *:before,
        *:after
        {
          box-sizing: inherit;
        }
        body {
          margin:0;
          background: #fafafa;
        }
      </style>
    </head>

    <body>
    <div id="swagger-ui"></div>

    <script src="/js/swagger-ui-bundle.js" charset="UTF-8"> </script>
    <script src="/js/swagger-ui-standalone-preset.js" charset="UTF-8"> </script>
    <script>
    window.onload = function() {
      // Begin Swagger UI call region
      const api_spec_url = new URL(window.location);
      api_spec_url.pathname = "<%= config.path %>";
      api_spec_url.hash = "";
      const ui = SwaggerUIBundle({
        url: api_spec_url.href,
        dom_id: '#swagger-ui',
        deepLinking: true,
        presets: [
          SwaggerUIBundle.presets.apis,
          SwaggerUIStandalonePreset
        ],
        plugins: [
          SwaggerUIBundle.plugins.DownloadUrl
        ],
        layout: "StandaloneLayout",
        requestInterceptor: function(request){
          request.headers["x-csrf-token"] = "<%= csrf_token %>";
          return request;
        }
        <%= for {k, v} <- Map.drop(config, [:path]) do %>
        , <%= camelize(k) %>: <%= OpenApiSpex.OpenApi.json_encoder().encode!(v) %>
        <% end %>
      })
      // End Swagger UI call region
      window.ui = ui
    }
    </script>
    </body>
    </html>
  """

  @doc """
  Initializes the plug.

  ## Options

   * `:path` - Required. The URL path to the API definition.
   * all other opts - forwarded to the `SwaggerUIBundle` constructor

  ## Example

      get "/swaggerui", OpenApiSpex.Plug.SwaggerUI,
        path: "/api/openapi",
        default_model_expand_depth: 3,
        display_operation_id: true
  """
  @impl Plug
  def init(opts) when is_list(opts) do
    Map.new(opts)
  end

  @impl Plug
  def call(conn, config) do
    csrf_token = Plug.CSRFProtection.get_csrf_token()
    html = render(config, csrf_token)

    conn
    |> Plug.Conn.put_resp_content_type("text/html")
    |> Plug.Conn.send_resp(200, html)
  end

  require EEx

  EEx.function_from_string(:defp, :render, @html, [
    :config,
    :csrf_token
  ])

  defp camelize(identifier) do
    identifier
    |> to_string
    |> String.split("_", parts: 2)
    |> case do
         [first] -> first
         [first, rest] -> first <> Macro.camelize(rest)
       end
  end
end
