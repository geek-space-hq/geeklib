# frozen_string_literal: true

require 'rspec'
require 'net/http'
require 'uri'
require 'json'

require 'active_record'
require_relative '../../db/connection'
require_relative '../../models/book'
Connection.to_test

RSpec.describe '/books' do
  after :each do
    Model::User.delete_all
  end

  (Thread.fork do
    require_relative '../../main'
    Sinatra::Application.run!
  end).run
  sleep 0.5

  route = 'http://localhost:4567/books'

  describe 'post: /' do
    uri = URI.parse(route + '/')
    request = Net::HTTP::Post.new(uri)

    it 'registers the new book' do
      request.set_form_data({ 'title' => 'Land of Lisp', 'author' => 'Conrad Barski' })
      Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }

      expect(Model::Book.find_by(title: 'Land of Lisp')).not_to be_nil
    end

    it 'returns the new book information as json' do
      request.set_form_data({ 'title' => 'Land of Lisp', 'author' => 'Conrad Barski' })
      response = Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }
      book = JSON.parse(response.body)

      expect(book['title']).to eq 'Land of Lisp'
      expect(book['author']).to eq 'Conrad Barski'
    end

    it 'returns "The title is nil" with 406 if the title is nil' do
      request.set_form_data({ 'author' => 'Conrad Barski' })
      response = Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }
      body = JSON.parse(response.body)

      expect(response.code).to eq '406'
      expect(body['cause']).to eq 'The title is nil'
    end

    it 'returns "The author is nil" with 406 if the author is nil' do
      request.set_form_data({ 'title' => 'Land of Lisp' })
      response = Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }
      body = JSON.parse(response.body)

      expect(response.code).to eq '406'
      expect(body['cause']).to eq 'The author is nil'
    end
  end

  describe 'get: /books/{book.id}' do
    let(:book) do
      uri = URI.parse(route + '/')
      create_request = Net::HTTP::Post.new(uri)
      create_request.set_form_data({ 'title' => 'Land of Lisp', 'author' => 'Conrad Barski' })
      JSON.parse((Net::HTTP.start(uri.host, uri.port) { |http| http.request(create_request) }).body)
    end

    it 'returns the book information as json' do
      uri = URI.parse(route + '/' + book['id'])
      request = Net::HTTP::Get.new(uri)
      response = Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }
      body = JSON.parse(response.body)
      expect(body).to eq book
    end

    it 'returns "The book was not found" with 404 if the user is not exist' do
      uri = URI.parse(route + '/' + '...')
      request = Net::HTTP::Get.new(uri.path)
      response = Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }

      expect(response.code).to eq '404'
      expect(JSON.parse(response.body)['cause']).to eq 'The book was not found'
    end
  end

  describe 'delete: /books/{book.id}' do
    let(:book) do
      uri = URI.parse(route + '/')
      create_request = Net::HTTP::Post.new(uri)
      create_request.set_form_data({ 'title' => 'SICP', 'author' => 'Harold Abelson' })
      JSON.parse((Net::HTTP.start(uri.host, uri.port) { |http| http.request(create_request) }).body)
    end

    let(:uri) { URI.parse("#{route}/#{book['id']}") }
    let(:request) { Net::HTTP::Delete.new(uri.path) }

    it 'deletes the book' do
      Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }

      expect(Model::Book.find_by(id: book['id'])).to be_nil
    end

    it 'returns the book information as JSON' do
      response = Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }

      expect(JSON.parse(response.body)).to eq book
    end

    it 'returns "The book was not found" with 404 if the user is not exist' do
      Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) } # delete
      response = Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) } # delete twice

      expect(response.code).to eq '404'
      expect(JSON.parse(response.body)['cause']).to eq 'The book was not found'
    end
  end
end
