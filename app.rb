# frozen_string_literal: true

require_relative 'config'

class MyAppController < Sinatra::Base
  get '/' do
    'Hello world!'
  end

  get '/restaurants.json' do
    content_type :json

    @restaurants = Restaurant.all
    json @restaurants
  end
end
