# frozen_string_literal: true

require 'active_record'

module Connection
  def self.to_production
    ActiveRecord::Base.establish_connection(
      adapter: 'postgresql',
      database: 'geeklib_production'
    )
  end

  def self.to_development
    ActiveRecord::Base.establish_connection(
      adapter: 'postgresql',
      database: 'geeklib_development'
    )
  end

  def self.to_test
    ActiveRecord::Base.establish_connection(
      adapter: 'postgresql',
      database: 'geeklib_test'
    )
  end
end
