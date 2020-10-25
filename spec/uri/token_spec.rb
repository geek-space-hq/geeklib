# frozen_string_literal: true

require 'rspec'
require 'net/http'
require 'uri'
require 'json'

require 'active_record'
require_relative '../../db/connection'
require_relative '../../models/user'
require_relative '../../models/token'

Connection.to_test

RSpec.describe '/tokens' do
  after :each do
    Model::User.delete_all
    Model::Token.delete_all
  end

  (Thread.fork do
    require_relative '../../main'
    Sinatra::Application.run!
  end).run
  sleep 0.5

  host = 'http://localhost:4567'
  route = 'http://localhost:4567/tokens'

  describe 'post: /' do
    let(:data) { { 'name' => 'Tatiana', 'password' => 'abcde' } }
    let(:uri) { URI.parse("#{route}/") }

    let(:token) do
      JSON.parse(
        Net::HTTP.post_form(URI.parse(host + '/users/'), data).body
      )
    end

    let(:user) { token['user'] }

    let(:request) do
      request = Net::HTTP::Post.new(uri.path)
      request
    end

    it 'creates new token' do
      request.set_form_data data
      user
      response = Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }
      token = JSON.parse(response.body)
      expect(Model::Token.find_by(token: token['token'])).not_to be_nil
    end

    it 'returns "The user was not found"' do
      user
      request.set_form_data({ 'name' => '(@ v @)', 'password' => 'abcde' })
      response = Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }
      expect(JSON.parse(response.body)['cause']).to eq 'The user was not found'
    end

    it 'returns "The password is invalid"' do
      user
      request.set_form_data({ 'name' => 'Tatiana', 'password' => 'HOGE' })
      response = Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }
      expect(JSON.parse(response.body)['cause']).to eq 'The password is invalid'
    end
  end
end
