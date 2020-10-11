# frozen_string_literal: true

require 'sinatra'
require 'securerandom'
require 'json'
require_relative './db/connection'
require_relative './models/user'

Connection.to_test

post '/users/' do
  return [406, { cause: 'The name is nil' }.to_json] if params['name'].nil?

  user = Model::User.create(
    id: SecureRandom.uuid,
    name: params['name']
  )

  { id: user.id, name: user.name }.to_json
end
