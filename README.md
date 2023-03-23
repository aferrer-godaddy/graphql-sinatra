# GraphQL using Sinatra - How to

## Step 0 - [Create a Rails GraphQL](https://github.com/andrerferrer/graphql-rails-demo#goal)

First, I created a Rails GraphQL application. It was pretty straightforward.

## Step 1 - [Create a Sinatra app](https://github.com/aferrer-godaddy/graphql-sinatra/commit/c7686f659736a9a99e72ea123d4b078eaa351f98)
Then, I created a simple Sinatra app.

```ruby
require 'sinatra'

get '/' do
  'Hello world!'
end
```

Now, we could run `bundle exec puma` (or `ruby app.rb`), make a GET request to localhost:4567 and receive a `"Hello world!"`.

I also added all the boilerplate needed to have a database.

Run `bundle exec db:create db:migrate db:seed` to create a DB and add a few Restaurants.

Great! Now we just have to make it be a graphql endpoint haha

## Step 2 - How does Rails initialize the graphql gem?

I checked how Rails handled the graphql generation to "reverse engineer" it.

When we run `rails generate graphql:install` it generate these:

```sh
Running via Spring preloader in process 26319
      create  app/graphql/types
      create  app/graphql/types/.keep
      create  app/graphql/testing_generator_schema.rb
      create  app/graphql/types/base_object.rb
      create  app/graphql/types/base_argument.rb
      create  app/graphql/types/base_field.rb
      create  app/graphql/types/base_enum.rb
      create  app/graphql/types/base_input_object.rb
      create  app/graphql/types/base_interface.rb
      create  app/graphql/types/base_scalar.rb
      create  app/graphql/types/base_union.rb
      create  app/graphql/types/query_type.rb
add_root_type  query
      create  app/graphql/mutations
      create  app/graphql/mutations/.keep
      create  app/graphql/mutations/base_mutation.rb
      create  app/graphql/types/mutation_type.rb
add_root_type  mutation
      create  app/controllers/graphql_controller.rb
       route  post "/graphql", to: "graphql#execute"
     gemfile  graphiql-rails
       route  graphiql-rails
      create  app/graphql/types/node_type.rb
      insert  app/graphql/types/query_type.rb
      create  app/graphql/types/base_connection.rb
      create  app/graphql/types/base_edge.rb
      insert  app/graphql/types/base_object.rb
      insert  app/graphql/types/base_object.rb
      insert  app/graphql/types/base_union.rb
      insert  app/graphql/types/base_union.rb
      insert  app/graphql/types/base_interface.rb
      insert  app/graphql/types/base_interface.rb
      insert  app/graphql/testing_generator_schema.rb
Gemfile has been modified, make sure you `bundle install`
```

Alright. We need a Route, a Controller#Action and the GraphQL Data.

We've got a new route:
```ruby
  if Rails.env.development?
    mount GraphiQL::Rails::Engine, at: "/graphiql", graphql_path: "/graphql"
  end
  post "/graphql", to: "graphql#execute"
```

And we've got a new controller:

```ruby
# app/controllers/graphql_controller.rb

class GraphqlController < ApplicationController
  # If accessing from outside this domain, nullify the session
  # This allows for outside API access while preventing CSRF attacks,
  # but you'll have to authenticate your user separately
  # protect_from_forgery with: :null_session

  def execute
    variables = prepare_variables(params[:variables])
    query = params[:query]
    operation_name = params[:operationName]
    context = {
      # Query context goes here, for example:
      # current_user: current_user,
    }
    result = TestingGeneratorSchema.execute(query, variables: variables, context: context, operation_name: operation_name)
    render json: result
  rescue StandardError => e
    raise e unless Rails.env.development?
    handle_error_in_development(e)
  end

  private

  # Handle variables in form data, JSON body, or a blank value
  def prepare_variables(variables_param)
    case variables_param
    when String
      if variables_param.present?
        JSON.parse(variables_param) || {}
      else
        {}
      end
    when Hash
      variables_param
    when ActionController::Parameters
      variables_param.to_unsafe_hash # GraphQL-Ruby will validate name and type of incoming variables.
    when nil
      {}
    else
      raise ArgumentError, "Unexpected parameter: #{variables_param}"
    end
  end

  def handle_error_in_development(e)
    logger.error e.message
    logger.error e.backtrace.join("\n")

    render json: { errors: [{ message: e.message, backtrace: e.backtrace }], data: {} }, status: 500
  end
end
```

Interesting...

Let's see this `TestingGeneratorSchema`:

```ruby
class TestingGeneratorSchema < GraphQL::Schema
  mutation(Types::MutationType)
  query(Types::QueryType)

  # For batch-loading (see https://graphql-ruby.org/dataloader/overview.html)
  use GraphQL::Dataloader

  # GraphQL-Ruby calls this when something goes wrong while running a query:
  def self.type_error(err, context)
    # if err.is_a?(GraphQL::InvalidNullError)
    #   # report to your bug tracker here
    #   return nil
    # end
    super
  end

  # Union and Interface Resolution
  def self.resolve_type(abstract_type, obj, ctx)
    # TODO: Implement this method
    # to return the correct GraphQL object type for `obj`
    raise(GraphQL::RequiredImplementationMissingError)
  end

  # Stop validating when it encounters this many errors:
  validate_max_errors(100)

  # Relay-style Object Identification:

  # Return a string UUID for `object`
  def self.id_from_object(object, type_definition, query_ctx)
    # For example, use Rails' GlobalID library (https://github.com/rails/globalid):
    object.to_gid_param
  end

  # Given a string UUID, find the object
  def self.object_from_id(global_id, query_ctx)
    # For example, use Rails' GlobalID library (https://github.com/rails/globalid):
    GlobalID.find(global_id)
  end
end
```

Alright, it uses `Types::MutationType` for mutations and `Types::QueryType` for queries.

Let's see both of them:

```ruby
module Types
  class MutationType < Types::BaseObject
    # TODO: remove me
    field :test_field, String, null: false,
      description: "An example field added by the generator"
    def test_field
      "Hello World"
    end
  end
end
```

```ruby
module Types
  class QueryType < Types::BaseObject
    # Add `node(id: ID!) and `nodes(ids: [ID!]!)`
    include GraphQL::Types::Relay::HasNodeField
    include GraphQL::Types::Relay::HasNodesField

    # Add root-level fields here.
    # They will be entry points for queries on your schema.

    # TODO: remove me
    field :test_field, String, null: false,
      description: "An example field added by the generator"
    def test_field
      "Hello World!"
    end
  end
end
```

They refer to other classes, but let's stop here for now. It looks almost straightforward.

## Step 3 - Adding graphql in Sinatra

1. [Add Graphql-Type](https://github.com/aferrer-godaddy/graphql-sinatra/commit/588d9b88ae18017a98fbe3dbeb309f9a423b0fab)

Now, it was just a matter of adding a type:
```ruby
# graphql/types/restaurant_type.rb
module Types
  class Restaurant < Types::BaseObject
    description 'A Restaurant Type'

    field :id, ID, null: false
    field :title, String
    field :rating, Int
  end
end
```

1. [Add Graphql-Query](https://github.com/aferrer-godaddy/graphql-sinatra/commit/7ace8a23a7f1274715b6b242891c51d5455a0395)

And, a query:
```ruby
# graphql/query.rb
require_relative 'types/base_object'
require_relative 'types/restaurant_type'

module Types
  class QueryType < Types::BaseObject
    # Add root-level fields here.
    # They will be entry points for queries on your schema.

    field :restaurants, [Types::Restaurant], null: false do
      description 'Fetch all Restaurants'
    end

    def restaurants
      Restaurant.all
    end
  end
end
```

1. [Add Graphql-Schema](https://github.com/aferrer-godaddy/graphql-sinatra/commit/de973dea607e37557d06a1242dab6a1e7bf1ada7)

```ruby
# graphql/schema.rb
class MyAppSchema < GraphQL::Schema
  query(Types::QueryType)
end
```

## Step 4 - [Add GraphQL endpoint](https://github.com/aferrer-godaddy/graphql-sinatra/commit/4033030b58f961d01d6103d058209ff4784695f4)

```ruby
# app.rb
  post '/graphql' do
    result = MyAppSchema.execute(
      params[:query]
    )

    json result
  end
```

And now you can fetch it using your favorite way. I chose Postman:
![sinatra graphql](https://user-images.githubusercontent.com/101724621/227294965-1465b532-eb98-4418-85b5-b9021fa725ba.png)
