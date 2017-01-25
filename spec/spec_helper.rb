require 'rspec'
require 'active_record'
require 'factory_girl'
require 'database_cleaner'
require 'ffaker'
require 'pry'
require_relative '../lib/structor'

ActiveRecord::Base.establish_connection(
    "adapter"  => "sqlite3",
    "database" => ":memory:"
)

Dir['./spec/support/**/*.rb'].each { |f| require(File.expand_path(f)) }

# Turns off messaging during spec running of table creation
ActiveRecord::Migration.verbose = false
ActiveRecord::Schema.define do
  create_table :users do |t|
    t.string :first_name
    t.string :last_name
    t.string :email
    t.datetime :created_at, null: false
    t.datetime :updated_at, null: false
  end

  create_table :products do |t|
    t.string :name
    t.string :description
    t.decimal  :price, precision: 12, scale: 2, null: false
    t.datetime :created_at, null: false
    t.datetime :updated_at, null: false
  end

  create_table :looks do |t|
    t.string   :name
    t.belongs_to :user
    t.text     :description
    t.datetime :created_at, null: false
    t.datetime :updated_at, null: false
  end

  create_table :looks_products, force: :cascade do |t|
    t.belongs_to :look
    t.belongs_to :product
  end
end

class User < ActiveRecord::Base
  has_many :looks
end

class Look < ActiveRecord::Base
  has_and_belongs_to_many :products
  belongs_to :user
end

class Product < ActiveRecord::Base
  has_and_belongs_to_many :looks
end
