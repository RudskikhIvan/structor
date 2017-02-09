require_relative './spec_helper'
describe 'With the has one associtation' do

  describe 'as_hashes' do

    describe 'without options' do
      before :each do
        create_list :address, 3
      end

      it 'does not instantiate models' do
        expect(Address).to_not receive(:instantiate)
        expect(User).to_not receive(:instantiate)
        expect(User.as_hashes(include: :address).size).to eq(3)
      end

      it 'returns hashes with all keys' do
        hashes = User.as_hashes(include: :address)
        expect(hashes).to all have_keys('id', 'first_name', 'last_name', 'email', 'created_at', 'updated_at', 'address')
        expect(hashes.map{|h| h['address']}).to all(
          have_keys('id', 'user_id', 'address', 'city_id', 'approved', 'created_at', 'updated_at'))
      end

      it 'returns hashes with correct values' do
        User.includes(:address).all.zip(User.as_hashes(include: :address)) do |user, hash|
          expect(user.attributes).to eq(hash.except('address'))
          expect(user.address.attributes).to eq(hash['address'])
        end
      end
    end

    describe 'with only option' do
      before :each do
        create_list :address, 3
      end

      it 'does not instantiate models' do
        expect(Address).to_not receive(:instantiate)
        expect(User).to_not receive(:instantiate)
        expect(User.as_hashes(include: {address: {only: %i[address zip_code]}}).size).to eq(3)
      end

      it 'returns hashes with selected keys' do
        hashes = User.as_hashes(include: {address: {only: %i[id address]}})
        expect(hashes).to all have_keys('id', 'first_name', 'last_name', 'email', 'created_at', 'updated_at', 'address')
        expect(hashes.map{|h| h['address']}).to all match({
          'id' => a_kind_of(Integer),
          'address' => a_kind_of(String),
          'user_id' => a_kind_of(Integer)
        })
      end

      it 'returns hashes with correct values' do
        hashes = User.as_hashes(include: {address: {only: %i[id address approved created_at]}})
        User.includes(:address).all.zip(hashes) do |user, hash|
          expect(user.attributes).to eq(hash.except('address'))
          expect(user.address.attributes.slice(*%w[id address approved created_at user_id])).to eq(hash['address'])
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
        expect(User.as_hashes(include: {address: {except: %i[created_at updated_at]}}).size).to eq(3)
      end

      it 'returns hashes without excepted keys' do
        hashes = User.as_hashes(include: {address: {except: %i[city_id created_at updated_at]}})
        expect(hashes).to all have_keys('id', 'first_name', 'last_name', 'email', 'created_at', 'updated_at', 'address')
        expect(hashes.map{|h| h['address']}).to all match({
           'id' => a_kind_of(Integer),
           'user_id' => a_kind_of(Integer),
           'address' => a_kind_of(String),
           'zip_code' => a_kind_of(String),
           'approved' => a_kind_of_boolean
        })
      end

      it 'returns hashes with correct values' do
        hashes = User.as_hashes(include: {address: {except: %i[city_id created_at updated_at]}})
        User.includes(:address).all.zip(hashes) do |user, hash|
          expect(user.attributes).to eq(hash.except('address'))
          expect(user.address.attributes.slice(*%w[id address user_id approved zip_code])).to eq(hash['address'])
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
        expect(User.as_hashes(include: {address: {procs: {code: ->(h){ "##{h['zip_code']}" }}}}).size).to eq(3)
      end

      it 'returns hashes with virtual key' do
        hashes = User.as_hashes(include: {address: {procs: {code: ->(h){ "##{h['zip_code']}" }}}})
        expect(hashes).to all have_keys('id', 'first_name', 'last_name', 'email', 'created_at', 'updated_at', 'address')
        expect(hashes.map{|h| h['address']}).to all(
          have_keys('id', 'address', 'user_id', 'city_id', 'zip_code', 'code'))
      end

      it 'returns hashes with correct values' do
        hashes = User.as_hashes(include: {address: {procs: {code: ->(h){ "##{h['zip_code']}"}}}})
        User.includes(:address).zip(hashes) do |user, hash|
          expect(user.attributes).to eq(hash.except('address'))
          expect(user.address.attributes).to eq(hash['address'].except('code'))
          expect(hash['address']['code']).to eq("##{user.address.zip_code}")
        end
      end
    end

    describe 'with sql alias' do
      before :each do
        create_list :address, 3
      end

      it 'does not instantiate models' do
        expect(Address).to_not receive(:instantiate)
        expect(User).to_not receive(:instantiate)
        expect(User.as_hashes(include: {address: {only: [:id, "'#' || zip_code as code"]}}).size).to eq(3)
      end

      it 'returns hashes with virtual key' do
        hashes = User.as_hashes(include: {address: {only: [:id, "'#' || zip_code as code"]}})
        expect(hashes).to all have_keys('id', 'first_name', 'last_name', 'email', 'created_at', 'updated_at', 'address')
        expect(hashes.map{|h| h['address']}).to all have_keys('id', 'code')
      end

      it 'returns hashes with correct values' do
        hashes = User.as_hashes(include: {address: {only: [:id, "'#' || zip_code as code"]}})
        User.includes(:address).zip(hashes) do |user, hash|
          expect(user.attributes).to eq(hash.except('address'))
          expect(user.address.attributes.slice('id', 'user_id')).to eq(hash['address'].except('code'))
          expect(hash['address']['code']).to eq("##{user.address.zip_code}")
        end
      end
    end
  end

  describe 'as_structs' do

    describe 'without options' do
      before :each do
        create_list :address, 3
      end

      it 'does not instantiate models' do
        expect(Address).to_not receive(:instantiate)
        expect(User).to_not receive(:instantiate)
        expect(User.as_structs(include: :address).size).to eq(3)
      end

      it 'returns structs with all keys' do
        structs = User.as_structs(include: :address)
        expect(structs.map(&:to_h)).to all have_keys(*%i[id first_name last_name email created_at updated_at address])
        expect(structs.map{|s| s.address.to_h}).to all have_keys(*%i[id user_id address city_id approved created_at updated_at zip_code])
      end

      it 'returns structs with correct values' do
        User.includes(:address).all.zip(User.as_structs(include: :address)) do |user, struct|
          expect(user.attributes.symbolize_keys).to eq(struct.to_h.except(:address))
          expect(user.address.attributes.symbolize_keys).to eq(struct.address.to_h)
        end
      end
    end

    describe 'with only option' do
      before :each do
        create_list :address, 3
      end

      it 'does not instantiate models' do
        expect(Address).to_not receive(:instantiate)
        expect(User).to_not receive(:instantiate)
        expect(User.as_structs(include: {address: {only: %i[id address]}}).size).to eq(3)
      end

      it 'returns structs with selected keys' do
        structs = User.as_structs(include: {address: {only: %i[id address]}})
        expect(structs.map(&:to_h)).to all have_keys(*%i[id first_name last_name email created_at updated_at address])
        expect(structs.map{|s| s.address.to_h}).to all match({
          id: a_kind_of(Integer),
          user_id: a_kind_of(Integer),
          address: a_kind_of(String)
        })
      end

      it 'returns structs with correct values' do
        structs = User.as_structs(include: {address: {only: %i[id address approved created_at]}})
        User.includes(:address).all.zip(structs) do |user, struct|
          expect(user.attributes.symbolize_keys).to eq(struct.to_h.except(:address))
          expect(user.address.attributes.slice(*%w[id address approved created_at user_id]).symbolize_keys).to eq(struct.address.to_h)
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
        expect(User.as_structs(include: {address: {except: %i[approved created_at updated_at]}}).size).to eq(3)
      end

      it 'returns structs without excepted keys' do
        structs = User.as_structs(include: {address: {except: %i[approved created_at updated_at city_id]}})
        expect(structs.map(&:to_h)).to all have_keys(*%i[id first_name last_name email created_at updated_at address])
        expect(structs.map{|s| s.address.to_h}).to all match({
          id: a_kind_of(Integer),
          user_id: a_kind_of(Integer),
          address: a_kind_of(String),
          zip_code: a_kind_of(String)
        })
      end

      it 'returns structs with correct values' do
        structs = User.as_structs(include: {address: {except: %i[approved created_at updated_at]}})
        User.includes(:address).all.zip(structs) do |user, struct|
          expect(user.attributes.symbolize_keys).to eq(struct.to_h.except(:address))
          expect(user.address.attributes.slice(*%w[id address user_id zip_code city_id]).symbolize_keys).to eq(struct.address.to_h)
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
        expect(User.as_structs(include: {address: {procs: {code: ->(h){ "##{h['zip_code']}" }}}}).size).to eq(3)
      end

      it 'returns structs with virtual key' do
        structs = User.as_structs(include: {address: {procs: {code: ->(h){ "##{h['zip_code']}" }}}})
        expect(structs.map(&:to_h)).to all have_keys(*%i[id first_name last_name email created_at updated_at address])
        expect(structs.map{|s| s.address.to_h}).to all have_keys(*%i[id address user_id city_id zip_code code])
      end

      it 'returns structs with correct values' do
        structs = User.as_structs(include: {address: {procs: {code: ->(h){ "##{h['zip_code']}" }}}})
        User.includes(:address).zip(structs) do |user, struct|
          expect(user.attributes.symbolize_keys).to eq(struct.to_h.except(:address))
          expect(user.address.attributes.symbolize_keys).to eq(struct.address.to_h.except(:code))
          expect(struct.address.code).to eq("##{user.address.zip_code}")
        end
      end
    end

    describe 'with sql alias' do
      before :each do
        create_list :address, 3
      end

      it 'does not instantiate models' do
        expect(Address).to_not receive(:instantiate)
        expect(User).to_not receive(:instantiate)
        expect(User.as_structs(include: {address: {only: [:id, "'#' || zip_code as code"]}}).size).to eq(3)
      end

      it 'returns structs with virtual key' do
        structs = User.as_structs(include: {address: {only: [:id, "'#' || zip_code as code"]}})
        expect(structs.map(&:to_h)).to all have_keys(*%i[id first_name last_name email created_at updated_at address])
        expect(structs.map{|s| s.address.to_h}).to all have_only_keys(*%i[id code])
      end

      it 'returns structs with correct values' do
        structs = User.as_structs(include: {address: {only: [:id, "'#' || zip_code as code"]}})
        User.includes(:address).zip(structs) do |user, struct|
          expect(user.attributes.symbolize_keys).to eq(struct.to_h.except(:address))
          expect(user.address.attributes.slice('id', 'user_id').symbolize_keys).to eq(struct.address.to_h.except(:code))
          expect(struct.address.code).to eq("##{user.address.zip_code}")
        end
      end
    end
  end


end