# frozen_string_literal: true

class MyAppSchema < GraphQL::Schema
  query(Types::QueryType)
end
