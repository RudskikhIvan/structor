require_relative './spec_helper'
require 'ruby-prof'
describe 'benchmark', benchmark: true do

  describe 'Single model' do

    let!(:products){ create_list(:product, 1000) }

    n = 10

    it 'All fields' do
      Benchmark.bmbm do |x|
        x.report('ActiveRecord') do
          n.times{ Product.all.map{|p| "#{p.id}, #{p.name}, #{p.description}, #{p.price}, #{p.created_at}, #{p.updated_at}"} }
        end

        x.report('Struct: hashes')do
          n.times{ Product.as_hashes.map{|p| "#{p['id']}, #{p['name']}, #{p['description']}, #{p['price']}, #{p['created_at']}, #{p['updated_at']}"} }
        end

        x.report('Struct: structs') do
          n.times{ Product.as_structs.map{|p| "#{p.id}, #{p.name}, #{p.description}, #{p.price}, #{p.created_at}, #{p.updated_at}"} }
        end
      end
    end

    it 'to json' do
      Benchmark.bm do |x|
        x.report('ActiveRecord') { n.times{ Product.all.to_json } }
        x.report('Struct: hashes') { n.times{ Product.as_hashes.to_json } }
        x.report('Struct: structs') { n.times{ Product.as_structs.to_json } }
      end
    end

    it 'Selected fields' do
      Benchmark.bm do |x|
        x.report('ActiveRecord'){ n.times{ Product.select('id, name').each{|p| "#{p.id}, #{p.name}" } } }
        x.report('Struct: hashes'){ n.times{ Product.as_hashes(only: %i[id name]).each{|p| "#{p['id']}, #{p['name']}" } } }
        x.report('Struct: structs'){ n.times{ Product.as_structs(only: %i[id name]).each{|p| "#{p.id}, #{p.name}" } } }
      end
    end

    # it 'Profile' do
    #   res = RubyProf.profile{ Product.as_hashes(only: %i[id name description price created_at updated_at]) }
    #   printer = RubyProf::CallStackPrinter.new(res)
    #   printer.print(File.new('profile.html', 'w'), :min_percent => 1)
    #
    #   res = RubyProf.profile{ Product.all.map(&:inspect) }
    #   printer = RubyProf::CallStackPrinter.new(res)
    #   printer.print(File.new('profile_record.html', 'w'), :min_percent => 1)
    # end

  end

  describe 'Has and belongs to many' do

    let!(:looks){ create_list(:look, 333, products: build_list(:product, 3)) }

    n = 10

    it 'All fields' do
      Benchmark.bmbm do |x|
        x.report('ActiveRecord') do
          n.times do
            Look.includes(:products).each do |look|
              look.products.map{|p| "#{look.id}, #{look.name}, #{look.description} | #{p.id}, #{p.name}, #{p.description}, #{p.price}, #{p.created_at}, #{p.updated_at}"}
            end
          end
        end

        x.report('Struct: hashes') do
          n.times do
            Look.as_hashes(include: :products).each do |look|
              look['products'].map{|p| "#{look['id']}, #{look['name']}, #{look['description']} | #{p['id']}, #{p['name']}, #{p['description']}, #{p['price']}, #{p['created_at']}, #{p['updated_at']}"}
            end
          end
        end

        x.report('Struct: structs') do
          n.times do
            Look.as_structs(include: :products).each do |look|
              look.products.map{|p| "#{look.id}, #{look.name}, #{look.description} | #{p.id}, #{p.name}, #{p.description}, #{p.price}, #{p.created_at}, #{p.updated_at}"}
            end
          end
        end
      end
    end

  end

  describe 'Has many through' do

    let!(:looks){ create_list(:look, 333, products: build_list(:product, 3)) }

    n = 10

    it 'All fields' do
      Benchmark.bmbm do |x|
        x.report('ActiveRecord') do
          n.times do
            User.includes(:products).each do |user|
              user.products.map{|p| "#{user.id}, #{user.first_name}, #{user.last_name}, #{user.created_at}, #{user.updated_at} | #{p.id}, #{p.name}, #{p.description}, #{p.price}, #{p.created_at}, #{p.updated_at}"}
            end
          end
        end

        x.report('Struct: hashes') do
          n.times do
            User.as_hashes(include: :products).each do |user|
              user['products'].map{|p| "#{user['id']}, #{user['name']}, #{user['description']}, #{user['created_at']}, #{user['updated_at']} | #{p['id']}, #{p['name']}, #{p['description']}, #{p['price']}, #{p['created_at']}, #{p['updated_at']}"}
            end
          end
        end

        x.report('Struct: structs') do
          n.times do
            User.as_structs(include: :products).each do |user|
              user.products.map{|p| "#{user.id}, #{user.first_name}, #{user.last_name}, #{user.created_at}, #{user.updated_at} | #{p.id}, #{p.name}, #{p.description}, #{p.price}, #{p.created_at}, #{p.updated_at}"}
            end
          end
        end
      end
    end

  end

end