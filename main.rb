# frozen_string_literal: true

require 'sinatra'
require 'securerandom'
require 'json'
require_relative './db/connection'
require_relative './models/user'
require_relative './models/book'
require_relative './models/borrowed_log'

Connection.to_test

post '/users/' do
  return [406, { cause: 'The name is nil' }.to_json] if params['name'].nil?

  user = Model::User.create(
    id: SecureRandom.uuid,
    name: params['name']
  )

  user.to_json
end

get '/users/:user_id' do
  user = Model::User.find_by(id: params['user_id'])

  return [404, { cause: 'The user was not found' }.to_json] if user.nil?

  user.to_json
end

put '/users/:user_id/name' do
  return [406, { cause: 'The name is nil' }.to_json] if params['name'].nil?

  user = Model::User.find_by(id: params['user_id'])

  return [404, { cause: 'The user was not found' }.to_json] if user.nil?

  user.name = params['name']
  user.save

  user.to_json
end

delete '/users/:user_id' do
  user = Model::User.find_by(id: params['user_id'])

  return [404, { cause: 'The user was not found' }.to_json] if user.nil?

  user.delete

  user.to_json
end

post '/users/:user_id/borrow/:book_id' do
  user = Model::User.find_by(id: params['user_id'])
  book = Model::Book.find_by(id: params['book_id'])

  return [404, { cause: 'The user was not found' }.to_json] if user.nil?
  return [404, { cause: 'The book was not found' }.to_json] if book.nil?
  return [403, { cause: 'The book is not available' }.to_json] unless book.status == 'available'

  Model::BorrowedLog.create(
    user_id: user.id,
    book_id: book.id
  )

  book.status = 'borrowed'
  book.save

  { user: user.attributes, book: book.attributes }.to_json
end

post '/users/:user_id/return/:book_id' do
  user = Model::User.find_by(id: params['user_id'])
  book = Model::Book.find_by(id: params['book_id'])

  return [404, { cause: 'The user was not found' }.to_json] if user.nil?
  return [404, { cause: 'The book was not found' }.to_json] if book.nil?
  return [403, { cause: 'The book is not borrowed' }.to_json] unless book.status == 'borrowed'

  book.status = 'avaliable'
  book.save

  { user: user.attributes, book: book.attributes }.to_json
end

post '/books/' do
  return [406, { cause: 'The title is nil' }.to_json] if params['title'].nil?

  return [406, { cause: 'The author is nil' }.to_json] if params['author'].nil?

  book = Model::Book.create(
    id: SecureRandom.uuid,
    title: params['title'],
    author: params['author']
  )

  book.attributes.to_json
end

get '/books/:book_id' do
  book = Model::Book.find_by(id: params['book_id'])

  return [404, { cause: 'The book was not found' }.to_json] if book.nil?

  book.attributes.to_json
end

delete '/books/:book_id' do
  book = Model::Book.find_by(id: params['book_id'])

  return [404, { cause: 'The book was not found' }.to_json] if book.nil?

  book.delete

  book.attributes.to_json
end
