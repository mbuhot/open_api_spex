defmodule OpenApiSpex.SchemaTest do
  use ExUnit.Case
  alias OpenApiSpex.Schema
  alias OpenApiSpexTest.{ApiSpec, Schemas}
  import OpenApiSpex.Test.Assertions

  doctest Schema

  describe "schema/1" do
    test "EntityWithDict Schema example matches schema" do
      api_spec = ApiSpec.spec()
      assert_schema(Schemas.EntityWithDict.schema().example, "EntityWithDict", api_spec)
    end

    test "User Schema example matches schema" do
      spec = ApiSpec.spec()

      assert_schema(Schemas.User.schema().example, "User", spec)
      assert_schema(Schemas.UserRequest.schema().example, "UserRequest", spec)
      assert_schema(Schemas.UserResponse.schema().example, "UserResponse", spec)
      assert_schema(Schemas.UsersResponse.schema().example, "UsersResponse", spec)
    end
  end

  describe "Cast nil" do
    test "to nullable type" do
      assert {:ok, nil} = Schema.cast(%Schema{nullable: true}, nil, %{})
      assert {:ok, nil} = Schema.cast(%Schema{type: :integer, nullable: true}, nil, %{})
      assert {:ok, nil} = Schema.cast(%Schema{type: :string, nullable: true}, nil, %{})
    end

    test "to non-nullable type" do
      assert {:error, _} = Schema.cast(%Schema {type: :string}, nil, %{})
      assert {:error, _} = Schema.cast(%Schema {type: :integer}, nil, %{})
      assert {:error, _} = Schema.cast(%Schema {type: :object}, nil, %{})
    end
  end

  describe "Cast boolean" do
    test "from boolean" do
      assert {:ok, true} = Schema.cast(%Schema{type: :boolean}, true, %{})
      assert {:ok, false} = Schema.cast(%Schema{type: :boolean}, false, %{})
    end

    test "from string" do
      assert {:ok, true} = Schema.cast(%Schema{type: :boolean}, "true", %{})
      assert {:ok, false} = Schema.cast(%Schema{type: :boolean}, "false", %{})
    end

    test "from invalid data type" do
      assert {:error, _} = Schema.cast(%Schema{type: :boolean}, "not a bool", %{})
      assert {:error, _} = Schema.cast(%Schema{type: :boolean}, 1, %{})
      assert {:error, _} = Schema.cast(%Schema{type: :boolean}, nil, %{})
      assert {:error, _} = Schema.cast(%Schema{type: :boolean}, [true], %{})
    end
  end

  describe "Cast integer" do
    test "from integer" do
      assert {:ok, -1} = Schema.cast(%Schema{type: :integer}, -1, %{})
      assert {:ok, 0} = Schema.cast(%Schema{type: :integer}, 0, %{})
      assert {:ok, 1} = Schema.cast(%Schema{type: :integer}, 1, %{})
      assert {:ok, 12345} = Schema.cast(%Schema{type: :integer}, 12345, %{})
    end

    test "from string" do
      assert {:ok, -1} = Schema.cast(%Schema{type: :integer}, "-1", %{})
      assert {:ok, 0} = Schema.cast(%Schema{type: :integer}, "0", %{})
      assert {:ok, 1} = Schema.cast(%Schema{type: :integer}, "1", %{})
      assert {:ok, 12345} = Schema.cast(%Schema{type: :integer}, "12345", %{})
      assert {:error, _} = Schema.cast(%Schema{type: :integer}, "not an int", %{})
      assert {:error, _} = Schema.cast(%Schema{type: :integer}, "3.14159", %{})
      assert {:error, _} = Schema.cast(%Schema{type: :integer}, "", %{})
    end

    test "from invalid data type" do
      assert {:error, _} = Schema.cast(%Schema{type: :integer}, true, %{})
      assert {:error, _} = Schema.cast(%Schema{type: :integer}, 3.14159, %{})
      assert {:error, _} = Schema.cast(%Schema{type: :integer}, nil, %{})
      assert {:error, _} = Schema.cast(%Schema{type: :integer}, [1, 2], %{})
    end
  end

  describe "Cast number" do
    test "from number" do
      assert {:ok, -1.0} = Schema.cast(%Schema{type: :number, format: :float}, -1, %{})
      assert {:ok, -1.0} = Schema.cast(%Schema{type: :number, format: :double}, -1, %{})
      assert {:ok, -1} = Schema.cast(%Schema{type: :number}, -1, %{})
      assert {:ok, 0.0} = Schema.cast(%Schema{type: :number}, 0.0, %{})
      assert {:ok, 1.0} = Schema.cast(%Schema{type: :number}, 1.0, %{})
      assert {:ok, 123.45} = Schema.cast(%Schema{type: :number}, 123.45, %{})
    end
    test "from string" do
      assert {:ok, -1.0} = Schema.cast(%Schema{type: :number}, "-1", %{})
      assert {:ok, 0.0} = Schema.cast(%Schema{type: :number}, "0.0", %{})
      assert {:ok, 1.0} = Schema.cast(%Schema{type: :number}, "1.0", %{})
      assert {:ok, 123.45} = Schema.cast(%Schema{type: :number}, "123.45", %{})
    end
    test "from invalid data type" do
      assert {:error, _} = Schema.cast(%Schema{type: :number}, nil, %{})
      assert {:error, _} = Schema.cast(%Schema{type: :number}, false, %{})
      assert {:error, _} = Schema.cast(%Schema{type: :number}, "", %{})
      assert {:error, _} = Schema.cast(%Schema{type: :number}, "not a number", %{})
      assert {:error, _} = Schema.cast(%Schema{type: :number}, [], %{})
      assert {:error, _} = Schema.cast(%Schema{type: :number}, [1.0, 2.0], %{})
    end
  end

  describe "cast string" do
    test "from string" do
      assert {:ok, ""} = Schema.cast(%Schema{type: :string}, "", %{})
      assert {:ok, "  "} = Schema.cast(%Schema{type: :string}, "  ", %{})
      assert {:ok, "hello"} = Schema.cast(%Schema{type: :string}, "hello", %{})
    end
    test "from invalid data type" do
      assert {:error, _} = Schema.cast(%Schema{type: :string}, nil, %{})
      assert {:error, _} = Schema.cast(%Schema{type: :string}, [], %{})
      assert {:error, _} = Schema.cast(%Schema{type: :string}, :an_atom, %{})
      assert {:error, _} = Schema.cast(%Schema{type: :string}, 0, %{})
    end
    test "format: :date" do
      assert {:error, _} = Schema.cast(%Schema{type: :string, format: :date}, "2018-01-1", %{})
      assert {:ok, _} = Schema.cast(%Schema{type: :string, format: :date}, "2018-01-01", %{})
    end
    test "format: :date-time" do
      assert {:error, _} = Schema.cast(%Schema{type: :string, format: :"date-time"}, "2018-01-01T00:00:0Z", %{})
      assert {:ok, _} = Schema.cast(%Schema{type: :string, format: :"date-time"}, "2018-01-01T00:00:00Z", %{})
    end
  end

  describe "cast array" do
    test "from list" do
      assert {:ok, []} = Schema.cast(%Schema{type: :array}, [], %{})
      assert {:ok, [1, 2, 3]} = Schema.cast(%Schema{type: :array}, [1,2,3], %{})
      assert {:ok, [1, "a", true]} = Schema.cast(%Schema{type: :array}, [1, "a", true], %{})

      int_array = %Schema{type: :array, items: %Schema{type: :integer}}
      assert {:ok, [1, 2, 3]} = Schema.cast(int_array, [1, 2, 3], %{})
      assert {:ok, [1, 2, 3]} = Schema.cast(int_array, ["1", "2", "3"], %{})
    end
    test "from invalid data type" do
      assert {:error, _} = Schema.cast(%Schema{type: :array}, nil, %{})
      assert {:error, _} = Schema.cast(%Schema{type: :array}, 0, %{})
      assert {:error, _} = Schema.cast(%Schema{type: :array}, "", %{})
      assert {:error, _} = Schema.cast(%Schema{type: :array}, "1,2,3", %{})
    end
    test "from list with invalid item type" do
      string_array = %Schema{type: :array, items: %Schema{type: :string}}
      assert {:error, _} = Schema.cast(string_array, [1, 2, 3], %{})
    end
  end

  describe "Cast object" do
    test "cast request schema" do
      api_spec = ApiSpec.spec()
      schemas = api_spec.components.schemas
      user_request_schema = schemas["UserRequest"]

      input = %{
        "user" => %{
          "id" => 123,
          "name" => "asdf",
          "email" => "foo@bar.com",
          "updated_at" => "2017-09-12T14:44:55Z"
        }
      }

      {:ok, output} = Schema.cast(user_request_schema, input, schemas)

      assert output == %OpenApiSpexTest.Schemas.UserRequest{
               user: %OpenApiSpexTest.Schemas.User{
                 id: 123,
                 name: "asdf",
                 email: "foo@bar.com",
                 updated_at: DateTime.from_naive!(~N[2017-09-12T14:44:55], "Etc/UTC")
               }
             }
    end

    test "cast/3 with unexpected type for object" do
      api_spec = ApiSpec.spec()
      schemas = api_spec.components.schemas
      user_request_schema = schemas["UserRequest"]

      input = []

      {:error, _output} = Schema.cast(user_request_schema, input, schemas)
    end

    test "cast/3 with unexpected type for nested object" do
      api_spec = ApiSpec.spec()
      schemas = api_spec.components.schemas
      user_request_schema = schemas["UserRequest"]

      input = %{
        "user" => []
      }

      {:error, _output} = Schema.cast(user_request_schema, input, schemas)
    end

    test "cast/3 with unexpected type for nested array" do
      api_spec = ApiSpec.spec()
      schemas = api_spec.components.schemas
      user_response_schema = schemas["UsersResponse"]

      input = %{
        "data" => %{}
      }

      {:error, _output} = Schema.cast(user_response_schema, input, schemas)
    end

    test "cast request schema with unexpected fields returns error" do
      api_spec = ApiSpec.spec()
      schemas = api_spec.components.schemas
      user_request_schema = schemas["UserRequest"]

      input = %{
        "user" => %{
          "id" => 123,
          "name" => "asdf",
          "email" => "foo@bar.com",
          "updated_at" => "2017-09-12T14:44:55Z",
          "unexpected_field" => "unexpected value"
        }
      }

      assert {:error, _} = Schema.cast(user_request_schema, input, schemas)
    end
  end

  describe "Polymorphic cast" do
    test "Cast Cat from Pet schema" do
      api_spec = ApiSpec.spec()
      schemas = api_spec.components.schemas
      pet_schema = schemas["Pet"]

      input = %{
        "pet_type" => "Cat",
        "meow" => "meow"
      }

      assert {:ok, %Schemas.Cat{meow: "meow", pet_type: "Cat"}} =
               Schema.cast(pet_schema, input, schemas)
    end

    test "Cast Dog from oneOf [cat, dog] schema" do
      api_spec = ApiSpec.spec()
      schemas = api_spec.components.schemas
      cat_or_dog = Map.fetch!(schemas, "CatOrDog")

      input = %{
        "pet_type" => "Cat",
        "meow" => "meow"
      }

      assert {:ok, %Schemas.Cat{meow: "meow", pet_type: "Cat"}} =
               Schema.cast(cat_or_dog, input, schemas)
    end

    test "`oneOf` - Cast number to string or number" do
      schema = %Schema{
        oneOf: [
          %Schema{type: :number},
          %Schema{type: :string}
        ]
      }

      result = Schema.cast(schema, "123", %{})

      assert {:ok, 123.0} = result
    end

    test "`oneOf` - Cast string to oneOf number or datetime" do
      schema = %Schema{
        oneOf: [
          %Schema{type: :number},
          %Schema{type: :string, format: :"date-time"}
        ]
      }

      assert {:ok, %DateTime{}} = Schema.cast(schema, "2018-04-01T12:34:56Z", %{})
    end

    test "`anyOf` - Cast string to anyOf number or datetime" do
      schema = %Schema{
        anyOf: [
          %Schema{type: :number},
          %Schema{type: :string, format: :"date-time"}
        ]
      }

      assert {:ok, %DateTime{}} = Schema.cast(schema, "2018-04-01T12:34:56Z", %{})
    end
  end

  describe "Integer validation" do
    test "Validate schema type integer when value is object" do
      schema = %Schema{
        type: :integer
      }

      assert {:error, _} = Schema.validate(schema, %{}, %{})
    end
  end

  describe "Number validation" do
    test "Validate schema type number when value is object" do
      schema = %Schema{
        type: :integer
      }

      assert {:error, _} = Schema.validate(schema, %{}, %{})
    end
  end

  describe "String validation" do
    test "Validate schema type string when value is object" do
      schema = %Schema{
        type: :string
      }

      assert {:error, _} = Schema.validate(schema, %{}, %{})
    end

    test "Validate schema type string when value is DateTime" do
      schema = %Schema{
        type: :string
      }

      assert {:error, _} = Schema.validate(schema, DateTime.utc_now(), %{})
    end

    test "Validate non-empty string with expected value" do
      schema = %Schema{type: :string, minLength: 1}
      assert :ok = Schema.validate(schema, "BLIP", %{})
    end
  end

  describe "DateTime validation" do
    test "Validate schema type string with format date-time when value is DateTime" do
      schema = %Schema{
        type: :string,
        format: :"date-time"
      }

      assert :ok = Schema.validate(schema, DateTime.utc_now(), %{})
    end
  end

  describe "Date Validation" do
    test "Validate schema type string with format date when value is Date" do
      schema = %Schema{
        type: :string,
        format: :date
      }

      assert :ok = Schema.validate(schema, Date.utc_today(), %{})
    end
  end

  describe "Enum validation" do
    test "Validate string enum with unexpected value" do
      schema = %Schema{
        type: :string,
        enum: ["foo", "bar"]
      }

      assert {:error, _} = Schema.validate(schema, "baz", %{})
    end

    test "Validate string enum with expected value" do
      schema = %Schema{
        type: :string,
        enum: ["foo", "bar"]
      }

      assert :ok = Schema.validate(schema, "bar", %{})
    end
  end

  describe "Object validation" do
    test "Validate schema type object when value is array" do
      schema = %Schema{
        type: :object
      }

      assert {:error, _} = Schema.validate(schema, [], %{})
    end

    test "Validate schema type object when value is DateTime" do
      schema = %Schema{
        type: :object
      }

      assert {:error, _} = Schema.validate(schema, DateTime.utc_now(), %{})
    end
  end

  describe "Array validation" do
    test "Validate schema type array when value is object" do
      schema = %Schema{
        type: :array
      }

      assert {:error, _} = Schema.validate(schema, %{}, %{})
    end
  end

  describe "Boolean validation" do
    test "Validate schema type boolean when value is object" do
      schema = %Schema{
        type: :boolean
      }

      assert {:error, _} = Schema.validate(schema, %{}, %{})
    end
  end

  describe "AnyOf validation" do
    test "Validate anyOf schema with valid value" do
      schema = %Schema{
        anyOf: [
          %Schema{type: :array},
          %Schema{type: :string}
        ]
      }

      assert :ok = Schema.validate(schema, "a string", %{})
    end

    test "Validate anyOf with value matching more than one schema" do
      schema = %Schema{
        anyOf: [
          %Schema{type: :number},
          %Schema{type: :integer}
        ]
      }

      assert :ok = Schema.validate(schema, 42, %{})
    end

    test "Validate anyOf schema with invalid value" do
      schema = %Schema{
        anyOf: [
          %Schema{type: :string},
          %Schema{type: :array}
        ]
      }

      assert {:error, _} = Schema.validate(schema, 3.14159, %{})
    end
  end

  describe "OneOf validation" do
    test "Validate oneOf schema with valid value" do
      schema = %Schema{
        oneOf: [
          %Schema{type: :string},
          %Schema{type: :array}
        ]
      }

      assert :ok = Schema.validate(schema, [1, 2, 3], %{})
    end

    test "Validate oneOf schema with invalid value" do
      schema = %Schema{
        oneOf: [
          %Schema{type: :string},
          %Schema{type: :array}
        ]
      }

      assert {:error, _} = Schema.validate(schema, 3.14159, %{})
    end

    test "Validate oneOf schema when matching multiple schemas" do
      schema = %Schema{
        oneOf: [
          %Schema{type: :object, properties: %{a: %Schema{type: :string}}},
          %Schema{type: :object, properties: %{b: %Schema{type: :string}}}
        ]
      }

      assert {:error, _} = Schema.validate(schema, %{a: "a", b: "b"}, %{})
    end
  end

  describe "AllOf validation" do
    test "Validate allOf schema with valid value" do
      schema = %Schema{
        allOf: [
          %Schema{type: :object, properties: %{a: %Schema{type: :string}}},
          %Schema{type: :object, properties: %{b: %Schema{type: :string}}}
        ]
      }

      assert :ok = Schema.validate(schema, %{a: "a", b: "b"}, %{})
    end

    test "Validate allOf schema with invalid value" do
      schema = %Schema{
        allOf: [
          %Schema{type: :object, properties: %{a: %Schema{type: :string}}},
          %Schema{type: :object, properties: %{b: %Schema{type: :string}}}
        ]
      }

      assert {:error, msg} = Schema.validate(schema, %{a: 1, b: 2}, %{})
      assert msg =~ "#/a"
      assert msg =~ "#/b"
    end

    test "Validate allOf with value matching not all schemas" do
      schema = %Schema{
        allOf: [
          %Schema{
            type: :integer,
            minimum: 5
          },
          %Schema{
            type: :integer,
            maximum: 40
          }
        ]
      }

      assert {:error, _} = Schema.validate(schema, 42, %{})
    end
  end

  describe "Not validation" do
    test "Validate not schema with valid value" do
      schema = %Schema{
        not: %Schema{type: :object}
      }

      assert :ok = Schema.validate(schema, 1, %{})
    end

    test "Validate not schema with invalid value" do
      schema = %Schema{
        not: %Schema{type: :object}
      }

      assert {:error, _} = Schema.validate(schema, %{a: 1}, %{})
    end

    test "Verify 'not' validation" do
      schema = %Schema{not: %Schema{type: :boolean}}
      assert :ok = Schema.validate(schema, 42, %{})
      assert :ok = Schema.validate(schema, "42", %{})
      assert :ok = Schema.validate(schema, nil, %{})
      assert :ok = Schema.validate(schema, 4.2, %{})
      assert :ok = Schema.validate(schema, [4], %{})
      assert :ok = Schema.validate(schema, %{}, %{})
      assert {:error, _} = Schema.validate(schema, true, %{})
      assert {:error, _} = Schema.validate(schema, false, %{})
    end
  end

  describe "Nullable validation" do
    test "Validate nullable-ified with expected value" do
      schema = %Schema{
        nullable: true,
        type: :string,
        minLength: 1
      }

      assert :ok = Schema.validate(schema, "BLIP", %{})
    end

    test "Validate nullable with expected value" do
      schema = %Schema{type: :string, nullable: true}
      assert :ok = Schema.validate(schema, nil, %{})
    end

    test "Validate nullable with unexpected value" do
      schema = %Schema{type: :string, nullable: true}
      assert :ok = Schema.validate(schema, "bla", %{})
    end
  end
end
