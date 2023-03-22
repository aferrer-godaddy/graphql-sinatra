# frozen_string_literal: true
require 'sinatra'
require 'sinatra/json'
require 'sinatra/activerecord'

# Read the config/database.yml file
# And connect to the database
config_path = File.join(__dir__, 'config/database.yml')
ActiveRecord::Base.configurations = YAML.load_file(config_path)
ActiveRecord::Base.establish_connection(:development)

# Load all models
Dir["#{__dir__}/models/*.rb"].sort.each { |file| require file }
