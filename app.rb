# frozen_string_literal: true

require_relative 'config'

class MyAppController < Sinatra::Base
  use Rack::JSONBodyParser

  get '/' do
    'Hello world!'
  end

  get '/restaurants.json' do
    content_type :json

    @restaurants = Restaurant.all
    json @restaurants
  end

  post '/graphql' do
    result = MyAppSchema.execute(
      params[:query]
    )
    json result
  end
end
