# Open API Spex

[![Elixir CI](https://github.com/open-api-spex/open_api_spex/actions/workflows/elixir.yml/badge.svg)](https://github.com/open-api-spex/open_api_spex/actions/workflows/elixir.yml)
[![Module Version](https://img.shields.io/hexpm/v/open_api_spex.svg)](https://hex.pm/packages/open_api_spex)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/open_api_spex/)
[![Total Download](https://img.shields.io/hexpm/dt/open_api_spex.svg)](https://hex.pm/packages/open_api_spex)
[![License](https://img.shields.io/hexpm/l/open_api_spex.svg)](https://github.com/open-api-spex/open_api_spex/blob/master/LICENSE)
[![Last Updated](https://img.shields.io/github/last-commit/open-api-spex/open_api_spex.svg)](https://github.com/open-api-spex/open_api_spex/commits/master)

Leverage Open API Specification 3 (formerly Swagger) to document, test, validate and explore your Plug and Phoenix APIs.

- Generate and serve a JSON Open API Spec document from your code
- Use the spec to cast request params to well defined schema structs
- Validate params against schemas, eliminate bad requests before they hit your controllers
- Validate responses against schemas in tests, ensuring your docs are accurate and reliable
- Explore the API interactively with [SwaggerUI](https://swagger.io/swagger-ui/)

Full documentation available on [HexDocs](https://hexdocs.pm/open_api_spex/).

## Installation

The package can be installed by adding `:open_api_spex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:open_api_spex, "~> 3.10"}
  ]
end
```

## Generate Spec

### Main Spec

Start by adding an `ApiSpec` module to your application to populate an `OpenApiSpex.OpenApi` struct.

```elixir
defmodule MyAppWeb.ApiSpec do
  alias OpenApiSpex.{Components, Info, OpenApi, Paths, Server}
  alias MyAppWeb.{Endpoint, Router}
  @behaviour OpenApi

  @impl OpenApi
  def spec do
    %OpenApi{
      servers: [
        # Populate the Server info from a phoenix endpoint
        Server.from_endpoint(Endpoint)
      ],
      info: %Info{
        title: "My App",
        version: "1.0"
      },
      # Populate the paths from a phoenix router
      paths: Paths.from_router(Router)
    }
    |> OpenApiSpex.resolve_schema_modules() # Discover request/response schemas from path specs
  end
end
```

Or you can use your application's spec values in the `info:` key.

```elixir
info: %Info{
  title: to_string(Application.spec(:my_app, :description)),
  version: to_string(Application.spec(:my_app, :vsn))
}
```

### Authorization

In case your API requires authorization you can add security schemes as part of the components in the main spec.

```elixir
components: %Components{
  securitySchemes: %{"authorization" => %SecurityScheme{type: "http", scheme: "bearer"}}
}
```

Once the security scheme is defined you can declare it. Please note that the key below matches the one defined in the security scheme, in the our example, `"authorization"`.

```elixir
security: [%{"authorization" => []}]
```

If you require authorization for all endpoints you can declare the `security` in the main spec. In case you need authorization only for specific endpoints, or if you are using more than one security scheme, you can declare it as part of each operation.

To learn more about the different security schemes please the check the [official documentation](https://swagger.io/docs/specification/authentication/).

### Operations

For each plug (controller) that will handle API requests, operations need
to be defined that the plug/controller will handle.

```elixir
defmodule MyAppWeb.UserController do
  use MyAppWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias MyAppWeb.Schemas.{UserParams, UserResponse}

  tags ["users"]
  security [%{}, %{"petstore_auth" => ["write:users", "read:users"]}]

  operation :update,
    summary: "Update user",
    parameters: [
      id: [in: :path, description: "User ID", type: :integer, example: 1001]
    ],
    request_body: {"User params", "application/json", UserParams},
    responses: [
      ok: {"User response", "application/json", UserResponse}
    ]

  def update(conn, %{"id" => id}) do
    json(conn, %{
      data: %{
        id: id,
        name: "joe user",
        email: "joe@gmail.com"
      }
    })
  end
end
```

Note: In order to prevent Elixir Formatter from automatically adding parentheses to the `ControllerSpecs` macro
call arguments, add `:open_api_spex` to the `import_deps` list in `.formatter.exs`:

.formatter.exs:

```elixir
[
  import_deps: [:open_api_spex]
]
```

There is a convenient shortcut `:type` for base data types supported by open api

```elixir
parameters: [
  id: [in: :query, type: :integer, required: true, description: "User ID", example: 1001]
]
```

The responses can also be defined using keyword list syntax,
and the HTTP status codes can be replaced with their text equivalents:

```elixir
responses: [
  ok: {"User response", "application/json", MyAppWeb.Schemas.UserResponse},
  unprocessable_entity: {"Bad request parameters", "application/json", MyAppWeb.Schemas.BadRequestParameters},
  not_found: {"Not found", "application/json", MyAppWeb.Schemas.NotFound}
]
```

The full set of atom keys are defined in `Plug.Conn.Status.code/1`.

Alternately, the HTTP status codes can be specified directly:

```elixir
responses: %{
  200 => {"User response", "application/json", MyAppWeb.Schemas.UserResponse},
  422 => {"Bad request parameters", "application/json", MyAppWeb.Schemas.BadRequestParameters},
  404 => {"Not found", "application/json", MyAppWeb.Schemas.NotFound}
}
```

If you need to omit the spec for some action then pass false to the
second argument of `operation/2` for the action:

```elixir
operation :create, false
```

Each definition in a controller action or plug operation is converted
to an `%OpenApiSpex.Operation{}` struct. The definitions are read
by your application's `ApiSpec` module, which in turn is
called from the `OpenApiSpex.Plug.PutApiSpex` plug on each request.
The definitions data is cached, so it does not actually extract the definitions on each request.

Note that the names of the OpenAPI fields follow `snake_case` naming convention instead of
OpenAPI's (and JSON Schema's) `camelCase` convention.

### Alternatives to ControllerSpecs-style Operation Specs

#### %Operation{}

If ControllerSpecs-style operation specs don't provide the flexibility you need, the `%Operation{}` struct
and related structs can be used instead. See the
[example user controller that uses `%Operation{}` structs](https://github.com/open-api-spex/open_api_spex/blob/master/examples/phoenix_app/lib/phoenix_app_web/controllers/user_controller_with_struct_specs.ex).

For examples of other action operations, see the
[example web app](https://github.com/open-api-spex/open_api_spex/blob/master/examples/phoenix_app/lib/phoenix_app_web/controllers/user_controller.ex).

### Schemas

Next, declare JSON schema modules for the request and response bodies.
In each schema module, call `OpenApiSpex.schema/1`, passing the schema definition. The schema must
have keys described in `OpenApiSpex.Schema.t`. This will define a `%OpenApiSpex.Schema{}` struct.
This struct is made available from the `schema/0` public function, which is generated by `OpenApiSpex.schema/1`.

You may optionally have the data described by the schema turned into a struct linked to the JSON schema by adding `"x-struct": __MODULE__`
to the schema.

```elixir
defmodule MyAppWeb.Schemas do
  alias OpenApiSpex.Schema

  defmodule User do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      # The title is optional. It defaults to the last section of the module name.
      # So the derived title for MyApp.User is "User".
      title: "User",
      description: "A user of the app",
      type: :object,
      properties: %{
        id: %Schema{type: :integer, description: "User ID"},
        name: %Schema{type: :string, description: "User name", pattern: ~r/[a-zA-Z][a-zA-Z0-9_]+/},
        email: %Schema{type: :string, description: "Email address", format: :email},
        birthday: %Schema{type: :string, description: "Birth date", format: :date},
        inserted_at: %Schema{
          type: :string,
          description: "Creation timestamp",
          format: :"date-time"
        },
        updated_at: %Schema{type: :string, description: "Update timestamp", format: :"date-time"}
      },
      required: [:name, :email],
      example: %{
        "id" => 123,
        "name" => "Joe User",
        "email" => "joe@gmail.com",
        "birthday" => "1970-01-01T12:34:55Z",
        "inserted_at" => "2017-09-12T12:34:55Z",
        "updated_at" => "2017-09-13T10:11:12Z"
      }
    })
  end

  defmodule UserResponse do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "UserResponse",
      description: "Response schema for single user",
      type: :object,
      properties: %{
        data: User
      },
      example: %{
        "data" => %{
          "id" => 123,
          "name" => "Joe User",
          "email" => "joe@gmail.com",
          "birthday" => "1970-01-01T12:34:55Z",
          "inserted_at" => "2017-09-12T12:34:55Z",
          "updated_at" => "2017-09-13T10:11:12Z"
        }
      }
    })
  end
end
```

For more examples of schema definitions, see the
[sample Phoenix app](https://github.com/open-api-spex/open_api_spex/blob/master/examples/phoenix_app/lib/phoenix_app_web/schemas.ex).

## Serve the Spec

To serve the API spec from your application, first add the `OpenApiSpex.Plug.PutApiSpec` plug somewhere in the pipeline.

```elixir
pipeline :api do
  plug OpenApiSpex.Plug.PutApiSpec, module: MyAppWeb.ApiSpec
end
```

Now the spec will be available for use in downstream plugs.
The `OpenApiSpex.Plug.RenderSpec` plug will render the spec as JSON:

```elixir
scope "/api" do
  pipe_through :api
  resources "/users", MyAppWeb.UserController, only: [:create, :index, :show]
  get "/openapi", OpenApiSpex.Plug.RenderSpec, []
end
```

## Generating the Spec

You can write the swagger file to disk using the following Mix task and optionally, for your
convenience, create a direct alias:

```shell
mix openapi.spec.json --spec MyAppWeb.ApiSpec
```

## Serve Swagger UI

Once your API spec is available through a route (see ["Serve the Spec"](#serve-the-spec)), the `OpenApiSpex.Plug.SwaggerUI` plug can be used to
serve a SwaggerUI interface. The `path:` plug option must be supplied to give the path to the API spec.

All JavaScript and CSS assets are sourced from cdnjs.cloudflare.com, rather than vendoring into this package.



```elixir
scope "/" do
  pipe_through :browser # Use the default browser stack

  get "/", MyAppWeb.PageController, :index
  get "/swaggerui", OpenApiSpex.Plug.SwaggerUI, path: "/api/openapi"
end

scope "/api" do
  pipe_through :api

  resources "/users", MyAppWeb.UserController, only: [:create, :index, :show]
  get "/openapi", OpenApiSpex.Plug.RenderSpec, []
end
```

## Assets can be installed into the local application

```shell
mix openapi.spec.install 'install_path'
```
```elixir
  scope "/" do
    pipe_through :browser # Use the default browser stack

    get "/", MyAppWeb.PageController, :index
    get "/swaggerui", OpenApiSpex.Plug.SwaggerUI.Local, path: "/api/openapi"
  end

  scope "/api" do
    pipe_through :api

    resources "/users", MyAppWeb.UserController, only: [:create, :index, :show]
    get "/openapi", OpenApiSpex.Plug.RenderSpec, []
  end
```

## Importing an existing schema file

> :warning: This functionality currently converts Strings into Atoms, which makes it potentially [vulnerable to DoS attacks](https://til.hashrocket.com/posts/gkwwfy9xvw-converting-strings-to-atoms-safely). We recommend that you load Open API Schemas from _known files_ during application startup and _not dynamically from external sources at runtime_.

OpenApiSpex has functionality to import an existing schema, casting it into an `%OpenApi{}` struct. This means you can load a schema that is JSON or YAML encoded. See the example below:

```elixir
# Importing an existing JSON encoded schema
open_api_spec_from_json = "encoded_schema.json"
  |> File.read!()
  |> Jason.decode!()
  |> OpenApiSpex.OpenApi.Decode.decode()

# Importing an existing YAML encoded schema
open_api_spec_from_yaml = "encoded_schema.yaml"
  |> YamlElixir.read_all_from_file!()
  |> List.first()
  |> OpenApiSpex.OpenApi.Decode.decode()
```

You can then use the loaded spec to with `OpenApiSpex.cast_and_validate/4`, like:

```elixir
{:ok, _} = OpenApiSpex.cast_and_validate(
  open_api_spec_from_json, # or open_api_spec_from_yaml
  spec.paths["/some_path"].post,
  test_conn,
  "application/json"
)
```

## Validating and Casting Params

OpenApiSpex can automatically validate requests before they reach the controller action function. Or if you prefer,
you can explicitly call on OpenApiSpex to cast and validate the params within the controller action.
See `OpenApiSpex.cast_value/3` for the latter.

The rest of this section describes implicit casting and validating the request before it reaches your controller action.

First, the `plug OpenApiSpex.Plug.PutApiSpec` needs to be called in the Router, as described above.

Add the `OpenApiSpex.Plug.CastAndValidate` plug to a controller to validate request parameters and to cast to Elixir types defined by the operation schema.

```elixir
# Phoenix
plug OpenApiSpex.Plug.CastAndValidate, json_render_error_v2: true
# Plug
plug OpenApiSpex.Plug.CastAndValidate, json_render_error_v2: true, operation_id: "UserController.create"
```

The `json_render_error_v2: true` is a work-around for a bug in the format of the default error renderer.
It will be not needed in version 4.0.

For Phoenix apps, the `operation_id` can be inferred from the contents of `conn.private`.

The data shape of the default error renderer follows the JSON:API spec for error responses. For
convenience, the `OpenApiSpex.JsonErrorResponse` schema module is available that specifies
the shape, and it can be used in your API specs.

Example usage of `CastAndValidate` in a Phoenix controller:

```elixir
defmodule MyAppWeb.UserController do
  use MyAppWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias MyAppWeb.Schemas.{UserParams, UserResponse}

  plug OpenApiSpex.Plug.CastAndValidate, json_render_error_v2: true

  operation :update,
    summary: "Update user",
    description: "Updates with the given params.\nThis is another line of text in the description."
    parameters: [
      id: [in: :path, type: :integer, description: "user ID"],
      vsn: [in: :query, type: :integer, description: "API version number"],
      "api-version": [in: :header, type: :integer, description: "API version number"]
    ],
    request_body: {"The user attributes", "application/json", UserParams},
    responses: %{
      201 => {"User", "application/json", UserResponse}
      422 => OpenApiSpex.JsonErrorResponse.response()
    }
  def update(
        conn = %{
          body_params: %UserParams{
            name: name,
            email: email,
            birthday: %Date{} = birthday
          }
        },
        %{id: id}
      ) do
    # conn.body_params cast to UserRequest struct
    # conn.params combines path params, query params and header params
    # conn.params.id cast to integer
    # conn.params.vsn cast to integer
    # conn.params[:"api-version"] cast to integer
    # params is the same as conn.params
    # params.id cast to integer

    # Note: Using pattern-matching in the action function's arguments can
    # cause Dialyzer to complain. This is because Dialyzer expects the
    # `conn` and `params` arguments to have string keys, not atom keys.
    # To resolve this, fetch the `:body_params` with
    # `body_params = Map.get(conn, :body_params)`.
  end
end
```

Now the client will receive a 422 response whenever the request fails to meet the validation rules from the api spec.

The response body will include the validation error message:

```json
{
  "errors": [
    {
      "detail": "Invalid format. Expected :date",
      "source": {
        "pointer": "/data/birthday"
      },
      "title": "Invalid value"
    }
  ]
}
```

If you would like a different response JSON shape, create a plug module to shape the response,
and pass it to `CastAndValidate`:

```elixir
plug OpenApiSpex.Plug.CastAndValidate, render_error: MyErrorRendererPlug
```

```elixir
defmodule MyErrorRendererPlug do
  @behaviour Plug

  alias Plug.Conn
  alias OpenApiSpex.OpenApi

  @impl Plug
  def init(errors), do: errors

  @impl Plug
  def call(conn, errors) when is_list(errors) do
    response = %{
      errors: Enum.map(errors, &to_string/1)
    }

    json = OpenApi.json_encoder().encode!(response)

    conn
    |> Conn.put_resp_content_type("application/json")
    |> Conn.send_resp(422, json)
  end
end
```

## Generate Examples

OpenApiSpex can generate example data from specs. This has a similar result as
SwaggerUI when it generates example requests or responses for an endpoint.
This is a convenient way to generate test data for controller/plug tests.

```elixir
use MyAppWeb.ConnCase

test "create/2", %{conn: conn} do
  request_body = OpenApiSpex.Schema.example(MyAppWeb.Schemas.UserRequest.schema())

  json =
    conn
    |> post(user_path(conn), request_body)
    |> json_response(200)
end
```

## Validate Examples

As schemas evolve, you may want to confirm that the examples given match the schemas.
Use the `OpenApiSpex.TestAssertions` module to assert on schema validations.

```elixir
use ExUnit.Case
import OpenApiSpex.TestAssertions

test "UsersResponse example matches schema" do
  api_spec = MyAppWeb.ApiSpec.spec()
  schema = MyAppWeb.Schemas.UsersResponse.schema()
  assert_schema(schema.example, "UsersResponse", api_spec)
end
```

## Validate Responses

API responses can be tested against schemas using `OpenApiSpex.TestAssertions` also:

```elixir
use MyAppWeb.ConnCase
import OpenApiSpex.TestAssertions

test "UserController produces a UsersResponse", %{conn: conn} do
  json =
    conn
    |> get(user_path(conn, :index))
    |> json_response(200)

  api_spec = MyAppWeb.ApiSpec.spec()
  assert_schema(json, "UsersResponse", api_spec)
end
```

## Copyright and License

Copyright (c) 2017 Michael Buhot

Licensed under the Mozilla Public License, Version 2.0, which can be found in [LICENSE](./LICENSE).
