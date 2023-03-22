# frozen_string_literal: true

module Types
  class Restaurant < Types::BaseObject
    description 'A Restaurant Type'

    field :id, ID, null: false
    field :title, String
    field :rating, Int
  end
end
