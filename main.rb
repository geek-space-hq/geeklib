# frozen_string_literal: true

require 'sinatra'
require 'securerandom'
require 'json'
require_relative './db/connection'
require_relative './models/user'
require_relative './models/book'
require_relative './models/borrowed_log'
require_relative './models/token'

Connection.to_test

post '/users/' do
  return [406, { cause: 'The name is nil' }.to_json] if params['name'].nil?

  return [406, { cause: 'The password is nil' }.to_json] if params['password'].nil?

  id = SecureRandom.uuid
  salt = Digest::SHA256.new.hexdigest(id)

  user = Model::User.create(
    id: id,
    name: params['name'],
    digest_password: (1..30).inject(params['password']) { Digest::SHA256.new.hexdigest(_1 + salt) }
  )

  token = Model::Token.create(
    token: SecureRandom.uuid,
    user_id: id
  )

  { token: token.token, user: { id: user.id, name: user.name } }.to_json
end

get '/users/:user_id' do
  user = Model::User.find_by(id: params['user_id'])

  return [404, { cause: 'The user was not found' }.to_json] if user.nil?

  { id: user.id, name: user.name }.to_json
end

put '/users/:user_id/name' do
  return [406, { cause: 'The name is nil' }.to_json] if params['name'].nil?

  user = Model::User.find_by(id: params['user_id'])

  token = request.env['HTTP_AUTHORIZATION'] && Model::Token.find_by(token: request.env['HTTP_AUTHORIZATION'])

  return [404, { cause: 'The user was not found' }.to_json] if user.nil?

  return [406, { cause: 'The authorization is invalid' }.to_json] if token.nil?

  return '' if request.env['HTTP_AUTHORIZATION'].nil?

  user.name = params['name']
  user.save

  { id: user.id, name: user.name }.to_json
end

delete '/users/:user_id' do
  user = Model::User.find_by(id: params['user_id'])

  token = request.env['HTTP_AUTHORIZATION'] && Model::Token.find_by(token: request.env['HTTP_AUTHORIZATION'])

  return [404, { cause: 'The user was not found' }.to_json] if user.nil?
  return [406, { cause: 'The authorization is invalid' }.to_json] if token.nil?

  user.delete

  { id: user.id, name: user.name }.to_json
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

  { user: { id: user.id, name: user.name }, book: book.attributes }.to_json
end

post '/users/:user_id/return/:book_id' do
  user = Model::User.find_by(id: params['user_id'])
  book = Model::Book.find_by(id: params['book_id'])

  return [404, { cause: 'The user was not found' }.to_json] if user.nil?
  return [404, { cause: 'The book was not found' }.to_json] if book.nil?
  return [403, { cause: 'The book is not borrowed' }.to_json] unless book.status == 'borrowed'

  book.status = 'avaliable'
  book.save

  { user: { id: user.id, name: user.name }, book: book.attributes }.to_json
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
