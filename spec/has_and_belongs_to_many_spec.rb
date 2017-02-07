require_relative './spec_helper'
describe 'With the has and belongs to many associtation' do

  describe 'as_hashes' do

    describe 'without options' do
      before :each do
        create_list(:look, 3)
      end

      it 'does not instantiate models' do
        expect(Look).to_not receive(:instantiate)
        expect(Product).to_not receive(:instantiate)
        expect(Look.as_hashes(include: :products).size).to eq(3)
      end

      it 'returns hashes with all keys' do
        hashes = Look.as_hashes(include: :products)
        expect(hashes).to all have_keys('id', 'name', 'description', 'user_id', 'created_at', 'updated_at', 'products')
        expect(hashes.flat_map{|h| h['products']}).to all have_keys('id', 'name', 'description', 'price', 'created_at', 'updated_at')
      end

      it 'returns hashes with correct values' do
        Look.includes(:products).all.zip(Look.as_hashes(include: :products)) do |look, hash|
          expect(look.attributes).to eq(hash.except('products'))
          look.products.zip(hash['products']){|product, h| expect(product.attributes).to eq(h) }
        end
      end
    end

    describe 'with only option' do
      before :each do
        create_list(:look, 3)
      end

      it 'does not instantiate models' do
        expect(Look).to_not receive(:instantiate)
        expect(Product).to_not receive(:instantiate)
        expect(Look.as_hashes(include: {products: {only: %i[name created_at]}}).size).to eq(3)
      end

      it 'returns hashes with selected keys' do
        hashes = Look.as_hashes(include: {products: {only: %i[id price]}})
        expect(hashes).to all have_keys('id', 'name', 'description', 'user_id', 'created_at', 'updated_at', 'products')
        expect(hashes.flat_map{|h| h['products']}).to all match({
          'id' => a_kind_of(Integer),
          'price' => a_kind_of(BigDecimal)
        })
      end

      it 'returns hashes with correct values' do
        hashes = Look.as_hashes(include: {products: {only: %i[id name created_at]}})
        Look.includes(:products).all.zip(hashes) do |look, hash|
          expect(look.attributes).to eq(hash.except('products'))
          look.products.zip(hash['products']){|product, h| expect(product.attributes.slice('id', 'name', 'created_at', 'user_id')).to eq(h) }
        end
      end
    end

    describe 'with except option' do
      before :each do
        create_list(:look, 3)
      end

      it 'does not instantiate models' do
        expect(Product).to_not receive(:instantiate)
        expect(Look).to_not receive(:instantiate)
        expect(Look.as_hashes(include: {products: {except: %i[description]}}).size).to eq(3)
      end

      it 'returns hashes without excepted keys' do
        hashes = Look.as_hashes(include: {products: {except: %i[description created_at updated_at]}})
        expect(hashes).to all have_keys('id', 'name', 'description', 'user_id', 'created_at', 'updated_at', 'products')
        expect(hashes.flat_map{|h| h['products']}).to all match({
          'id' => a_kind_of(Integer),
          'name' => a_kind_of(String),
          'price' => a_kind_of(BigDecimal)
        })
      end

      it 'returns hashes with correct values' do
        hashes = Look.as_hashes(include: {products: {except: %i[description updated_at]}})
        Look.includes(:products).all.zip(hashes) do |look, hash|
          expect(look.attributes).to eq(hash.except('products'))
          look.products.zip(hash['products']){|product, h| expect(product.attributes.slice('id', 'name', 'created_at', 'price')).to eq(h)}
        end
      end
    end

    describe 'with proc option' do
      before :each do
        create_list(:look, 3)
      end

      it 'does not instantiate models' do
        expect(Product).to_not receive(:instantiate)
        expect(Look).to_not receive(:instantiate)
        expect(Look.as_hashes(include: {products: {procs: {text_price: ->(h){ "$#{h['price']}"}}}}).size).to eq(3)
      end

      it 'returns hashes with virtual key' do
        hashes = Look.as_hashes(include: {products: {procs: {text_price: ->(h){ "$#{h['price']}"}}}})
        expect(hashes).to all have_keys('id', 'name', 'description', 'user_id', 'created_at', 'updated_at', 'products')
        expect(hashes.flat_map{|h| h['products']}).to all have_keys('id', 'name', 'description', 'price', 'created_at', 'updated_at', 'text_price')
      end

      it 'returns hashes with correct values' do
        hashes = Look.as_hashes(include: {products: {procs: {text_price: ->(h){ "$#{h['price']}"}}}})
        Look.includes(:products).zip(hashes) do |look, hash|
          expect(look.attributes).to eq(hash.except('products'))
          look.products.zip(hash['products']) do |product, h|
            expect(product.attributes).to eq(h.except('text_price'))
            expect("$#{product.price}").to eq(h['text_price'])
          end
        end
      end
    end

    describe 'with sql alias' do
      before :each do
        create_list(:look, 3)
      end

      it 'does not instantiate models' do
        expect(Look).to_not receive(:instantiate)
        expect(Product).to_not receive(:instantiate)
        expect(Look.as_hashes(include: {products: {only: [:id, "'$' || price as text_price"]}}).size).to eq(3)
      end

      it 'returns hashes with virtual key' do
        hashes = Look.as_hashes(include: {products: {only: [:id, "'$' || price as text_price"]}})
        expect(hashes).to all have_keys('id', 'name', 'description', 'user_id', 'created_at', 'updated_at', 'products')
        expect(hashes.flat_map{|h| h['products']}).to all have_keys('id', 'text_price')
      end

      it 'returns hashes with correct values' do
        hashes = Look.as_hashes(include: {products: {only: [:id, "'$' || price as text_price"]}})
        Look.includes(:products).zip(hashes) do |look, hash|
          expect(look.attributes).to eq(hash.except('products'))
          look.products.zip(hash['products']) do |product, h|
            expect(product.attributes.slice('id')).to eq(h.except('text_price'))
            expect("$#{product.price.to_i}").to eq(h['text_price'])
          end
        end
      end
    end

    describe 'empty associations' do
      before :each do
        create_list(:look, 3, products: [])
      end

      it 'returns an empty array when collection is empty' do
        expect(Look.as_hashes(include: :products)).to all include('products' => [])
      end

      it 'returns an empty array when collection is empty with only option' do
        expect(Look.as_hashes(include: {products: {only: %i[id name]}})).to all include('products' => [])
      end

      it 'returns an empty array when collection is empty with except option' do
        expect(Look.as_hashes(include: {products: {except: %i[description]}})).to all include('products' => [])
      end

      it 'returns an empty array when collection is empty with procs option' do
        expect(Look.as_hashes(include: {products: {procs: {'some_attr' => ->(h){ 'string' }}}})).to all include('products' => [])
      end
    end
  end

  describe 'as_structs' do

    describe 'without options' do
      before :each do
        create_list(:look, 3)
      end

      it 'does not instantiate models' do
        expect(Look).to_not receive(:instantiate)
        expect(Product).to_not receive(:instantiate)
        expect(Look.as_structs(include: :products).size).to eq(3)
      end

      it 'returns structs with all keys' do
        structs = Look.as_structs(include: :products)
        expect(structs.map(&:to_h)).to all have_keys(*%i[id name description user_id created_at updated_at products])
        expect(structs.flat_map{|s| s.products.map(&:to_h)}).to all have_keys(*%i[id name description price created_at updated_at])
      end

      it 'returns structs with correct values' do
        Look.includes(:products).all.zip(Look.as_structs(include: :products)) do |look, struct|
          expect(look.attributes.symbolize_keys).to eq(struct.to_h.except(:products))
          look.products.zip(struct.products){|product, s| expect(product.attributes.symbolize_keys).to eq(s.to_h) }
        end
      end
    end

    describe 'with only option' do
      before :each do
        create_list(:look, 3)
      end

      it 'does not instantiate models' do
        expect(Look).to_not receive(:instantiate)
        expect(Product).to_not receive(:instantiate)
        expect(Look.as_structs(include: {products: {only: %i[name created_at]}}).size).to eq(3)
      end

      it 'returns structs with selected keys' do
        structs = Look.as_structs(include: {products: {only: %i[id name]}})
        expect(structs.map(&:to_h)).to all have_keys(*%i[id name description user_id created_at updated_at products])
        expect(structs.flat_map{|h| h.products.map(&:to_h)}).to all match({
          id: a_kind_of(Integer),
          name: a_kind_of(String),
        })
      end

      it 'returns structs with correct values' do
        structs = Look.as_structs(include: {products: {only: %i[id name created_at]}})
        Look.includes(:products).all.zip(structs) do |look, struct|
          expect(look.attributes.symbolize_keys).to eq(struct.to_h.except(:products))
          look.products.zip(struct.products){|product, s|
            expect(product.attributes.slice('id', 'name', 'created_at').symbolize_keys).to eq(s.to_h) }
        end
      end
    end

    describe 'with except option' do
      before :each do
        create_list(:look, 3)
      end

      it 'does not instantiate models' do
        expect(Product).to_not receive(:instantiate)
        expect(Look).to_not receive(:instantiate)
        expect(Look.as_structs(include: {products: {except: %i[description]}}).size).to eq(3)
      end

      it 'returns structs without excepted keys' do
        structs = Look.as_structs(include: {products: {except: %i[description created_at updated_at]}})
        expect(structs.map(&:to_h)).to all have_keys(*%i[id name description user_id created_at updated_at products])
        expect(structs.flat_map{|s| s.products.map(&:to_h)}).to all match({
          id: a_kind_of(Integer),
          name: a_kind_of(String),
          price: a_kind_of(BigDecimal)
        })
      end

      it 'returns structs with correct values' do
        structs = Look.as_structs(include: {products: {except: %i[description updated_at]}})
        Look.includes(:products).all.zip(structs) do |look, struct|
          expect(look.attributes.symbolize_keys).to eq(struct.to_h.except(:products))
          look.products.zip(struct.products){|product, s|
            expect(product.attributes.slice('id', 'name', 'created_at', 'price').symbolize_keys).to eq(s.to_h)}
        end
      end
    end

    describe 'with proc option' do
      before :each do
        create_list(:look, 3)
      end

      it 'does not instantiate models' do
        expect(Product).to_not receive(:instantiate)
        expect(Look).to_not receive(:instantiate)
        expect(Look.as_structs(include: {products: {procs: {text_price: ->(h){ "$#{h['price']}"}}}}).size).to eq(3)
      end

      it 'returns structs with virtual key' do
        structs = Look.as_structs(include: {products: {procs: {text_price: ->(h){ "$#{h['price']}"}}}})
        expect(structs.map(&:to_h)).to all have_keys(*%i[id name description user_id created_at updated_at products])
        expect(structs.flat_map{|s| s.products.map(&:to_h)}).to all have_keys(*%i[id name description price created_at updated_at text_price])
      end

      it 'returns structs with correct values' do
        structs = Look.as_structs(include: {products: {procs: {text_price: ->(h){ "$#{h['price']}"}}}})
        Look.includes(:products).zip(structs) do |look, struct|
          expect(look.attributes.symbolize_keys).to eq(struct.to_h.except(:products))
          look.products.zip(struct.products) do |product, s|
            expect(product.attributes.symbolize_keys).to eq(s.to_h.except(:text_price))
            expect("$#{product.price}").to eq(s.text_price)
          end
        end
      end
    end

    describe 'with sql alias' do
      before :each do
        create_list(:look, 3)
      end

      it 'does not instantiate models' do
        expect(Look).to_not receive(:instantiate)
        expect(Product).to_not receive(:instantiate)
        expect(Look.as_structs(include: {products: {only: [:id, "'$' || price as text_price"]}}).size).to eq(3)
      end

      it 'returns structs with virtual key' do
        structs = Look.as_structs(include: {products: {only: [:id, "'$' || price as text_price"]}})
        expect(structs.map(&:to_h)).to all have_keys(*%i[id name description user_id created_at updated_at products])
        expect(structs.flat_map{|h| h.products.map(&:to_h)}).to all have_keys(*%i[id text_price])
      end

      it 'returns structs with correct values' do
        structs = Look.as_structs(include: {products: {only: [:id, "'$' || price as text_price"]}})
        Look.includes(:products).zip(structs) do |look, struct|
          expect(look.attributes.symbolize_keys).to eq(struct.to_h.except(:products))
          look.products.zip(struct.products) do |look, s|
            expect(look.attributes.slice('id').symbolize_keys).to eq(s.to_h.except(:text_price))
            expect("$#{look.price.to_i}").to eq(s.text_price)
          end
        end
      end
    end

    describe 'empty associations' do
      before :each do
        create_list(:look, 3, products: [])
      end

      it 'returns an empty array when collection is empty' do
        expect(Look.as_structs(include: :products).map(&:to_h)).to all include(products: [])
      end

      it 'returns an empty array when collection is empty with only option' do
        expect(Look.as_structs(include: {products: {only: %i[id name]}}).map(&:to_h)).to all include(products: [])
      end

      it 'returns an empty array when collection is empty with except option' do
        expect(Look.as_structs(include: {products: {except: %i[description]}}).map(&:to_h)).to all include(products: [])
      end

      it 'returns an empty array when collection is empty with procs option' do
        expect(Look.as_structs(include: {products: {procs: {'some_attr' => ->(h){ 'string' }}}}).map(&:to_h)).to all include(products: [])
      end
    end
  end

end