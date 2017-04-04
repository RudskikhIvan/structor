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
    t.timestamps
  end

  create_table :products do |t|
    t.string :name
    t.string :description
    t.decimal  :price, precision: 12, scale: 2, null: false
    t.timestamps
  end

  create_table :looks do |t|
    t.string   :name
    t.belongs_to :user
    t.text     :description
    t.timestamps
  end

  create_table :looks_products do |t|
    t.belongs_to :look
    t.belongs_to :product
  end

  create_table :addresses do |t|
    t.belongs_to :user
    t.string :address
    t.integer :city_id
    t.string :zip_code
    t.boolean :approved, default: false
    t.timestamps
  end

  create_table :cities do |t|
    t.string :name
    t.decimal :lat, precision: 10, scale: 7
    t.decimal :lng, precision: 10, scale: 7
  end

  create_table :likes do |t|
    t.belongs_to :user
    t.belongs_to :likeable, polymorphic: true
  end
end

class User < ActiveRecord::Base
  has_many :looks
  has_one :address
  has_one :city, through: :address
  has_many :products, through: :looks
  has_many :likes
end

class Look < ActiveRecord::Base
  has_and_belongs_to_many :products
  belongs_to :user
end

class Product < ActiveRecord::Base
  has_and_belongs_to_many :looks
end

class City < ActiveRecord::Base

end

class Address < ActiveRecord::Base
  belongs_to :user
  belongs_to :city
end

class Like < ActiveRecord::Base
  belongs_to :user
  belongs_to :likeable, polymorphic: true
end
