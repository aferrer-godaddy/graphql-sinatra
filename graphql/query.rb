# frozen_string_literal: true

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
      # Types::Restaurant and Restaurant can get dubious
      # ::Restaurant is used to refer to the latter
      ::Restaurant.all
    end
  end
end
