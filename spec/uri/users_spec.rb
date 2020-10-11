# frozen_string_literal: true

require 'rspec'
require 'net/http'
require 'uri'
require 'json'

require 'active_record'
require_relative '../../db/connection'
require_relative '../../models/user'

Connection.to_test

RSpec.describe '/users/' do
  after :each do
    Model::User.delete_all
  end

  (Thread.fork do
    require_relative '../../main'
    Sinatra::Application.run!
  end).run
  sleep 0.5

  host = 'http://localhost:4567'

  describe 'post: /users/' do
    uri = URI.parse(host + '/users/')

    it 'registers the new user' do
      Net::HTTP.post_form(uri, { 'name' => 'Hirota' })

      expect(Model::User.find_by(name: 'Hirota')).not_to be_nil
    end

    it 'returns the new user information as JSON' do
      response = Net::HTTP.post_form(uri, { 'name' => 'Hirota' })
      user_information = JSON.parse(response.body)

      expect(user_information['id']).not_to be_nil
      expect(user_information['name']).to eq 'Hirota'
    end

    it 'returns "The name is nil" with 406 if the name is nil' do
      response = Net::HTTP.post_form(uri, {})
      body = JSON.parse(response.body)

      expect(response.code).to eq '406'
      expect(body['cause']).to eq 'The name is nil'
    end
  end
end
