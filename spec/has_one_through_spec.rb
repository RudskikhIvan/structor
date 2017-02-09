require_relative './spec_helper'
describe 'With the has one through associtation' do

  describe 'as_hashes' do

    describe 'without options' do
      before :each do
        create_list :user, 3, :address
      end

      it 'does not instantiate models' do
        expect(User).to_not receive(:instantiate)
        expect(Address).to_not receive(:instantiate)
        expect(City).to_not receive(:instantiate)
        expect(User.as_hashes(include: :city).size).to eq(3)
      end

      it 'returns hashes with all keys' do
        hashes = User.as_hashes(include: :city)
        expect(hashes).to all have_keys('id', 'first_name', 'last_name', 'email', 'created_at', 'updated_at', 'city')
        expect(hashes.map{|h| h['city']}).to all(have_keys('id', 'name', 'lat', 'lng'))
      end

      it 'returns hashes with correct values' do
        User.includes(:city).all.zip(User.as_hashes(include: :city)) do |user, hash|
          expect(user.attributes).to eq(hash.except('city'))
          expect(user.city.attributes).to eq(hash['city'])
        end
      end
    end

    describe 'with only option' do
      before :each do
        create_list :user, 3, :address
      end

      it 'does not instantiate models' do
        expect(User).to_not receive(:instantiate)
        expect(Address).to_not receive(:instantiate)
        expect(City).to_not receive(:instantiate)
        expect(User.as_hashes(include: {city: {only: %i[name]}}).size).to eq(3)
      end

      it 'returns hashes with selected keys' do
        hashes = User.as_hashes(include: {city: {only: %i[id name]}})
        expect(hashes).to all have_keys('id', 'first_name', 'last_name', 'email', 'created_at', 'updated_at', 'city')
        expect(hashes.map{|h| h['city']}).to all match({
          'id' => a_kind_of(Integer),
          'name' => a_kind_of(String)
        })
      end

      it 'returns hashes with correct values' do
        hashes = User.as_hashes(include: {city: {only: %i[id lat lng]}})
        User.includes(:city).all.zip(hashes) do |user, hash|
          expect(user.attributes).to eq(hash.except('city'))
          expect(user.city.attributes.slice(*%w[id lat lng])).to eq(hash['city'])
        end
      end
    end

    describe 'with except option' do
      before :each do
        create_list :user, 3, :address
      end

      it 'does not instantiate models' do
        expect(User).to_not receive(:instantiate)
        expect(Address).to_not receive(:instantiate)
        expect(City).to_not receive(:instantiate)
        expect(User.as_hashes(include: {address: {except: %i[created_at updated_at]}}).size).to eq(3)
      end

      it 'returns hashes without excepted keys' do
        hashes = User.as_hashes(include: {city: {except: %i[name]}})
        expect(hashes).to all have_keys('id', 'first_name', 'last_name', 'email', 'created_at', 'updated_at', 'city')
        expect(hashes.map{|h| h['city']}).to all match({
          'id' => a_kind_of(Integer),
          'lat' => a_kind_of(BigDecimal),
          'lng' => a_kind_of(BigDecimal)
        })
      end

      it 'returns hashes with correct values' do
        hashes = User.as_hashes(include: {city: {except: %i[lat lng]}})
        User.includes(:city).all.zip(hashes) do |user, hash|
          expect(user.attributes).to eq(hash.except('city'))
          expect(user.city.attributes.slice(*%w[id name])).to eq(hash['city'])
        end
      end
    end

    describe 'with proc option' do
      before :each do
        create_list :user, 3, :address
      end

      it 'does not instantiate models' do
        expect(User).to_not receive(:instantiate)
        expect(Address).to_not receive(:instantiate)
        expect(City).to_not receive(:instantiate)
        expect(User.as_hashes(include: {city: {procs: {geo: ->(h){ "#{h['lat']},#{h['lng']}" }}}}).size).to eq(3)
      end

      it 'returns hashes with virtual key' do
        hashes = User.as_hashes(include: {city: {procs: {geo: ->(h){ "#{h['lat']},#{h['lng']}" }}}})
        expect(hashes).to all have_keys('id', 'first_name', 'last_name', 'email', 'created_at', 'updated_at', 'city')
        expect(hashes.map{|h| h['city']}).to all(have_keys('id', 'name', 'lat', 'lng', 'geo'))
      end

      it 'returns hashes with correct values' do
        hashes = User.as_hashes(include: {city: {procs: {geo: ->(h){ "#{h['lat']},#{h['lng']}" }}}})
        User.includes(:city).zip(hashes) do |user, hash|
          expect(user.attributes).to eq(hash.except('city'))
          expect(user.city.attributes).to eq(hash['city'].except('geo'))
          expect(hash['city']['geo']).to eq("#{user.city.lat},#{user.city.lng}")
        end
      end
    end

    describe 'with sql alias' do
      before :each do
        create_list :address, 3
      end

      it 'does not instantiate models' do
        expect(User).to_not receive(:instantiate)
        expect(Address).to_not receive(:instantiate)
        expect(City).to_not receive(:instantiate)
        expect(User.as_hashes(include: {city: {only: [:id, "lat || ',' || lng as geo"]}}).size).to eq(3)
      end

      it 'returns hashes with virtual key' do
        hashes = User.as_hashes(include: {city: {only: [:id, "lat || ',' || lng as geo"]}})
        expect(hashes).to all have_keys('id', 'first_name', 'last_name', 'email', 'created_at', 'updated_at', 'city')
        expect(hashes.map{|h| h['city']}).to all have_keys('id', 'geo')
      end

      it 'returns hashes with correct values' do
        hashes = User.as_hashes(include: {city: {only: [:id, "lat || ',' || lng as geo"]}})
        User.includes(:city).zip(hashes) do |user, hash|
          expect(user.attributes).to eq(hash.except('city'))
          expect(user.city.attributes.slice('id', 'user_id')).to eq(hash['city'].except('geo'))
          expect(hash['city']['geo']).to eq("#{user.city.lat.to_f},#{user.city.lng.to_f}")
        end
      end
    end

    describe 'empty associations' do
      before :each do
        create_list :user, 3
      end

      it 'returns nil when record does not exist' do
        expect(User.as_hashes(include: :city)).to all include('city' => nil)
      end

      it 'returns nil when record does not exist with only option' do
        expect(User.as_hashes(include: {city: {only: %i[id name]}})).to all include('city' => nil)
      end

      it 'returns nil when record does not exist with except option' do
        expect(User.as_hashes(include: {city: {except: %i[lat lng]}})).to all include('city' => nil)
      end

      it 'returns nil when record does not exist with procs option' do
        expect(User.as_hashes(include: {city: {procs: {'some_attr' => ->(h){ 'string' }}}})).to all include('city' => nil)
      end
    end
  end

  describe 'as_structs' do

    describe 'without options' do
      before :each do
        create_list :address, 3
      end

      it 'does not instantiate models' do
        expect(User).to_not receive(:instantiate)
        expect(Address).to_not receive(:instantiate)
        expect(City).to_not receive(:instantiate)
        expect(User.as_structs(include: :city).size).to eq(3)
      end

      it 'returns structs with all keys' do
        structs = User.as_structs(include: :city)
        expect(structs.map(&:to_h)).to all have_keys(*%i[id first_name last_name email created_at updated_at city])
        expect(structs.map{|s| s.city.to_h}).to all have_keys(*%i[id name lat lng])
      end

      it 'returns structs with correct values' do
        User.includes(:city).all.zip(User.as_structs(include: :city)) do |user, struct|
          expect(user.attributes.symbolize_keys).to eq(struct.to_h.except(:city))
          expect(user.city.attributes.symbolize_keys).to eq(struct.city.to_h)
        end
      end
    end

    describe 'with only option' do
      before :each do
        create_list :address, 3
      end

      it 'does not instantiate models' do
        expect(User).to_not receive(:instantiate)
        expect(Address).to_not receive(:instantiate)
        expect(City).to_not receive(:instantiate)
        expect(User.as_structs(include: {city: {only: %i[id name]}}).size).to eq(3)
      end

      it 'returns structs with selected keys' do
        structs = User.as_structs(include: {city: {only: %i[id name]}})
        expect(structs.map(&:to_h)).to all have_keys(*%i[id first_name last_name email created_at updated_at city])
        expect(structs.map{|s| s.city.to_h}).to all match({
          id: a_kind_of(Integer),
          name: a_kind_of(String)
        })
      end

      it 'returns structs with correct values' do
        structs = User.as_structs(include: {city: {only: %i[id lat lng]}})
        User.includes(:city).all.zip(structs) do |user, struct|
          expect(user.attributes.symbolize_keys).to eq(struct.to_h.except(:city))
          expect(user.city.attributes.slice(*%w[id lat lng]).symbolize_keys).to eq(struct.city.to_h)
        end
      end
    end

    describe 'with except option' do
      before :each do
        create_list :address, 3
      end

      it 'does not instantiate models' do
        expect(User).to_not receive(:instantiate)
        expect(Address).to_not receive(:instantiate)
        expect(City).to_not receive(:instantiate)
        expect(User.as_structs(include: {city: {except: %i[lat lng]}}).size).to eq(3)
      end

      it 'returns structs without excepted keys' do
        structs = User.as_structs(include: {city: {except: %i[lat lng]}})
        expect(structs.map(&:to_h)).to all have_keys(*%i[id first_name last_name email created_at updated_at city])
        expect(structs.map{|s| s.city.to_h}).to all match({
          id: a_kind_of(Integer),
          name: a_kind_of(String)
        })
      end

      it 'returns structs with correct values' do
        structs = User.as_structs(include: {city: {except: %i[name]}})
        User.includes(:city).all.zip(structs) do |user, struct|
          expect(user.attributes.symbolize_keys).to eq(struct.to_h.except(:city))
          expect(user.city.attributes.slice(*%w[id lat lng]).symbolize_keys).to eq(struct.city.to_h)
        end
      end
    end

    describe 'with proc option' do
      before :each do
        create_list :address, 3
      end

      it 'does not instantiate models' do
        expect(User).to_not receive(:instantiate)
        expect(Address).to_not receive(:instantiate)
        expect(City).to_not receive(:instantiate)
        expect(User.as_structs(include: {city: {procs: {geo: ->(s){ "#{s.lat},#{s.lng}" }}}}).size).to eq(3)
      end

      it 'returns structs with virtual key' do
        structs = User.as_structs(include: {city: {procs: {geo: ->(s){ "#{s.lat},#{s.lng}" }}}})
        expect(structs.map(&:to_h)).to all have_keys(*%i[id first_name last_name email created_at updated_at city])
        expect(structs.map{|s| s.city.to_h}).to all have_keys(*%i[id name lat lng geo])
      end

      it 'returns structs with correct values' do
        structs = User.as_structs(include: {city: {procs: {geo: ->(s){ "#{s.lat},#{s.lng}" }}}})
        User.includes(:city).zip(structs) do |user, struct|
          expect(user.attributes.symbolize_keys).to eq(struct.to_h.except(:city))
          expect(user.city.attributes.symbolize_keys).to eq(struct.city.to_h.except(:geo))
          expect(struct.city.geo).to eq("#{user.city.lat},#{user.city.lng}")
        end
      end
    end

    describe 'with sql alias' do
      before :each do
        create_list :address, 3
      end

      it 'does not instantiate models' do
        expect(User).to_not receive(:instantiate)
        expect(Address).to_not receive(:instantiate)
        expect(City).to_not receive(:instantiate)
        expect(User.as_structs(include: {city: {only: [:id, "lat || ',' || lng as geo"]}}).size).to eq(3)
      end

      it 'returns structs with virtual key' do
        structs = User.as_structs(include: {city: {only: [:id, "lat || ',' || lng as geo"]}})
        expect(structs.map(&:to_h)).to all have_keys(*%i[id first_name last_name email created_at updated_at city])
        expect(structs.map{|s| s.city.to_h}).to all have_only_keys(*%i[id geo])
      end

      it 'returns structs with correct values' do
        structs = User.as_structs(include: {city: {only: [:id, "lat || ',' || lng as geo"]}})
        User.includes(:city).zip(structs) do |user, struct|
          expect(user.attributes.symbolize_keys).to eq(struct.to_h.except(:city))
          expect(user.city.attributes.slice('id').symbolize_keys).to eq(struct.city.to_h.except(:geo))
          expect(struct.city.geo).to eq("#{user.city.lat},#{user.city.lng}")
        end
      end
    end

    describe 'empty associations' do
      before :each do
        create_list(:user, 3)
      end

      it 'returns nil when when record does not exist' do
        expect(User.as_structs(include: :city).map(&:to_h)).to all include(city: nil)
      end

      it 'returns nil when when record does not exist with only option' do
        expect(User.as_structs(include: {city: {only: %i[id name]}}).map(&:to_h)).to all include(city: nil)
      end

      it 'returns nil when when record does not exist with except option' do
        expect(User.as_structs(include: {city: {except: %i[lat lng]}}).map(&:to_h)).to all include(city: nil)
      end

      it 'returns nil when when record does not exist with procs option' do
        expect(User.as_structs(include: {city: {procs: {'some_attr' => ->(h){ 'string' }}}}).map(&:to_h)).to all include(city: nil)
      end
    end
  end

end