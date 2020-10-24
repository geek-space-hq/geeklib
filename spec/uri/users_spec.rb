# frozen_string_literal: true

require 'rspec'
require 'net/http'
require 'uri'
require 'json'

require 'active_record'
require_relative '../../db/connection'
require_relative '../../models/user'
require_relative '../../models/borrowed_log'
require_relative '../../models/token'

Connection.to_test

RSpec.describe '/users' do
  after :each do
    Model::User.delete_all
    Model::Book.delete_all
    Model::BorrowedLog.delete_all
    Model::Token.delete_all
  end

  (Thread.fork do
    require_relative '../../main'
    Sinatra::Application.run!
  end).run
  sleep 0.5

  host = 'http://localhost:4567'

  describe 'post: /' do
    uri = URI.parse(host + '/users/')
    let(:request) { Net::HTTP::Post.new(uri) }
    let(:data) { { 'name' => 'Hirota', 'password' => 'abcde' } }

    it 'registers the new user' do
      request.set_form_data(data)
      Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }

      user = Model::User.find_by(name: 'Hirota')
      expect(user).not_to be_nil
      expect(Model::Token.find_by(user_id: user.id)).not_to be_nil
    end

    it "returns the new user's token as JSON" do
      request.set_form_data(data)
      response = Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }
      token_information = JSON.parse(response.body)

      expect(token_information['user']['id']).not_to be_nil
      expect(token_information['user']['name']).to eq 'Hirota'
      expect(token_information['user']['digest_password']).to be_nil
    end

    it 'returns "The name is nil" with 406 if the name is nil' do
      request.set_form_data({ 'password' => 'abcde' })
      response = Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }
      body = JSON.parse(response.body)

      expect(response.code).to eq '406'
      expect(body['cause']).to eq 'The name is nil'
    end

    it 'returns "The password is nil" with 406 if the password is nil' do
      request.set_form_data({ 'name' => 'Hirota' })
      response = Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }
      body = JSON.parse(response.body)

      expect(response.code).to eq '406'
      expect(body['cause']).to eq 'The password is nil'
    end

    it 'digests the password' do
      request.set_form_data(data)
      response = Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }
      user_information = JSON.parse(response.body)

      expect(Model::User.find_by(id: user_information['user']['id']).digest_password).not_to eq data['password']
    end
  end

  describe 'get: /{user.id}' do
    let(:data) { { 'name' => 'Hirota', 'password' => 'abcde' } }

    it 'returns the user information as json' do
      post_response = Net::HTTP.post_form(URI.parse(host + '/users/'), data)
      user_information = JSON.parse(post_response.body)['user']
      user_id = user_information['id']

      uri = URI.parse(host + '/users/' + user_id)
      request = Net::HTTP::Get.new(uri.path)
      response = Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }

      expect(JSON.parse(response.body)).to eq user_information
    end

    it 'returns "The user was not found" with 404 if the user is not exist' do
      uri = URI.parse(host + '/users/' + 'None')
      request = Net::HTTP::Get.new(uri.path)
      response = Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }

      expect(response.code).to eq '404'
      expect(JSON.parse(response.body)['cause']).to eq 'The user was not found'
    end
  end

  describe 'put: /{user.id}/name' do
    let(:data) { { 'name' => 'Hirota', 'password' => 'abcde' } }

    let(:token) do
      JSON.parse(
        Net::HTTP.post_form(URI.parse(host + '/users/'), data).body
      )
    end

    let(:user) { token['user'] }

    let(:uri) { URI.parse("#{host}/users/#{user['id']}/name") }
    let(:request) { Net::HTTP::Put.new(uri.path) }

    it 'updates the user name' do
      request.set_form_data({ 'name' => 'Alice' })
      Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }
      expect(Model::User.find_by(id: user['id']).name).to eq 'Alice'
    end

    it 'returns the updated user information as JSON' do
      request.set_form_data({ 'name' => 'Alice' })
      response = Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }
      updated_user_information = JSON.parse(response.body)
      expected = { 'id' => user['id'], 'name' => 'Alice' }

      expect(updated_user_information).to eq expected
    end

    it 'returns "The user was not found" with 404 if the user is not exist' do
      request = Net::HTTP::Put.new(URI.parse("#{host}/users/undefined/name"))
      request.set_form_data({ 'name' => 'Alice' })
      response = Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }

      expect(response.code).to eq '404'
      expect(JSON.parse(response.body)['cause']).to eq 'The user was not found'
    end

    it 'returns "The name is nil" with 406 if the name is nil' do
      response = Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }
      body = JSON.parse(response.body)

      expect(response.code).to eq '406'
      expect(body['cause']).to eq 'The name is nil'
    end
  end

  describe 'delete: /{user.id}' do
    let(:data) { { 'name' => 'Hirota', 'password' => 'abcde' } }

    let(:token) do
      JSON.parse(
        Net::HTTP.post_form(URI.parse(host + '/users/'), data).body
      )
    end

    let(:user) { token['user'] }

    let(:uri) { URI.parse("#{host}/users/#{user['id']}") }
    let(:request) { Net::HTTP::Delete.new(uri.path) }

    it 'deletes the user' do
      Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }

      expect(Model::User.find_by(id: user['id'])).to be_nil
    end

    it 'returns the user information as JSON' do
      response = Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }

      expect(JSON.parse(response.body)).to eq user
    end

    it 'returns "The user was not found" with 404 if the user is not exist' do
      Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) } # delete
      response = Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) } # delete twice

      expect(response.code).to eq '404'
      expect(JSON.parse(response.body)['cause']).to eq 'The user was not found'
    end
  end

  describe 'post: /{user.id}/borrow/{book.id}' do
    let(:data) { { 'name' => 'Hirota', 'password' => 'abcde' } }

    let(:token) do
      JSON.parse(
        Net::HTTP.post_form(URI.parse(host + '/users/'), data).body
      )
    end

    let(:user) { token['user'] }

    let(:book) do
      uri = URI.parse(host + '/books/')
      create_request = Net::HTTP::Post.new(uri)
      create_request.set_form_data({ 'title' => 'SICP', 'author' => 'Harold Abelson' })
      JSON.parse((Net::HTTP.start(uri.host, uri.port) { |http| http.request(create_request) }).body)
    end

    let(:uri) { URI.parse("#{host}/users/#{user['id']}/borrow/#{book['id']}") }
    let(:request) { Net::HTTP::Post.new(uri.path) }

    it 'creates the borrowed-log & update the book status' do
      Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }

      expect(Model::BorrowedLog.find_by(book_id: book['id'])).not_to be_nil
      expect(Model::Book.find_by(id: book['id']).status).to eq 'borrowed'
    end

    it 'returns the borrowed-log as json' do
      # response = Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }
      # book['status'] = 'borrowed'
      # expected = { 'user' => user, 'book' => book }

      # expect(JSON.parse(response.body)).to eq expected
    end

    it 'returns "The user was not found" with 404 if the user is not exist' do
      uri = URI.parse("#{host}/users/brabra/borrow/#{book['id']}")
      request = Net::HTTP::Post.new(uri.path)
      response = Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }

      expect(response.code).to eq '404'
      expect(JSON.parse(response.body)['cause']).to eq 'The user was not found'
    end

    it 'returns "The book was not found" with 404 if the book is not exist' do
      uri = URI.parse("#{host}/users/#{user['id']}/borrow/hogehoge")
      request = Net::HTTP::Post.new(uri.path)
      response = Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }

      expect(response.code).to eq '404'
      expect(JSON.parse(response.body)['cause']).to eq 'The book was not found'
    end

    it 'returns "The book is not available" with 403 if the book is not available' do
      Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) } # Borrow the book.
      response = Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) } # The book was borrowed

      expect(response.code).to eq '403'
      expect(JSON.parse(response.body)['cause']).to eq 'The book is not available'
    end
  end

  describe 'post: /{user.id}/return/{book.id}' do
    let(:data) { { 'name' => 'Hirota', 'password' => 'abcde' } }

    let(:token) do
      JSON.parse(
        Net::HTTP.post_form(URI.parse(host + '/users/'), data).body
      )
    end

    let(:user) { token['user'] }

    let(:book) do
      uri = URI.parse(host + '/books/')
      create_request = Net::HTTP::Post.new(uri)
      create_request.set_form_data({ 'title' => 'SICP', 'author' => 'Harold Abelson' })
      JSON.parse((Net::HTTP.start(uri.host, uri.port) { |http| http.request(create_request) }).body)
    end

    before :each do
      uri = URI.parse("#{host}/users/#{user['id']}/borrow/#{book['id']}")
      borrow_request = Net::HTTP::Post.new(uri)
      Net::HTTP.start(uri.host, uri.port) { |http| http.request(borrow_request) }
    end

    let(:uri) { URI.parse("#{host}/users/#{user['id']}/return/#{book['id']}") }
    let(:request) { Net::HTTP::Post.new(uri.path) }

    it 'returns the borrowed-log information as json' do
      response = Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }
      book['status'] = 'avaliable'
      expected = { 'user' => user, 'book' => book }

      expect(JSON.parse(response.body)).to eq expected
    end

    it 'returns "The user was not found" with 404 if the user is not exist' do
      uri = URI.parse("#{host}/users/brabra/return/#{book['id']}")
      request = Net::HTTP::Post.new(uri.path)
      response = Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }

      expect(response.code).to eq '404'
      expect(JSON.parse(response.body)['cause']).to eq 'The user was not found'
    end

    it 'returns "The book was not found" with 404 if the book is not exist' do
      uri = URI.parse("#{host}/users/#{user['id']}/return/hogehoge")
      request = Net::HTTP::Post.new(uri.path)
      response = Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }

      expect(response.code).to eq '404'
      expect(JSON.parse(response.body)['cause']).to eq 'The book was not found'
    end

    it 'returns "The book is not borrowed" with 403 if the book is not available' do
      Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) } # Return the book
      response = Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) } # The book is available

      expect(response.code).to eq '403'
      expect(JSON.parse(response.body)['cause']).to eq 'The book is not borrowed'
    end
  end
end
