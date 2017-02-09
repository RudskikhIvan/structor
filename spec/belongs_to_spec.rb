require_relative './spec_helper'
describe 'With the belongs to associtation' do

  describe 'as_hashes' do

    describe 'without options' do
      before :each do
        @looks = create_list :look, 3
      end

      it 'does not instantiate models' do
        expect(Look).to_not receive(:instantiate)
        expect(User).to_not receive(:instantiate)
        expect(Look.as_hashes(include: :user).size).to eq(3)
      end

      it 'returns hashes with all keys' do
        hashes = Look.as_hashes(include: :user)
        expect(hashes).to all have_keys('id', 'name', 'description', 'user', 'created_at', 'updated_at')
        expect(hashes.map{|h| h['user']}).to all have_keys('id', 'first_name', 'last_name', 'email', 'created_at', 'updated_at')
      end

      it 'returns hashes with correct values' do
        Look.includes(:user).all.zip(Look.as_hashes(include: :user)) do |look, hash|
          expect(look.attributes).to eq(hash.except('user'))
          expect(look.user.attributes).to eq(hash['user'])
        end
      end
    end

    describe 'with only option' do
      before :each do
        @looks = create_list :look, 3
      end

      it 'does not instantiate models' do
        expect(Look).to_not receive(:instantiate)
        expect(User).to_not receive(:instantiate)
        expect(Look.as_hashes(include: {user: {only: %i[first_name last_name]}}).size).to eq(3)
      end

      it 'returns hashes with selected keys' do
        hashes = Look.as_hashes(include: {user: {only: %i[id first_name]}})
        expect(hashes).to all have_keys('id', 'name', 'description', 'user', 'created_at', 'updated_at')
        expect(hashes.map{|h| h['user']}).to all match({
          'id' => a_kind_of(Integer),
          'first_name' => a_kind_of(String)
        })
      end

      it 'returns hashes with correct values' do
        hashes = Look.as_hashes(include: {user: {only: %i[id first_name created_at]}})
        Look.includes(:user).all.zip(hashes) do |look, hash|
          expect(look.attributes).to eq(hash.except('user'))
          expect(look.user.attributes.slice(*%w[id first_name created_at])).to eq(hash['user'])
        end
      end
    end

    describe 'with except option' do
      before :each do
        @looks = create_list :look, 3
      end

      it 'does not instantiate models' do
        expect(User).to_not receive(:instantiate)
        expect(Look).to_not receive(:instantiate)
        expect(Look.as_hashes(include: {user: {except: %i[first_name last_name]}}).size).to eq(3)
      end

      it 'returns hashes without excepted keys' do
        hashes = Look.as_hashes(include: {user: {except: %i[email created_at updated_at]}})
        expect(hashes).to all have_keys('id', 'name', 'description', 'user', 'created_at', 'updated_at')
        expect(hashes.map{|h| h['user']}).to all match({
           'id' => a_kind_of(Integer),
           'first_name' => a_kind_of(String),
           'last_name' => a_kind_of(String)
        })
      end

      it 'returns hashes with correct values' do
        hashes = Look.as_hashes(include: {user: {except: %i[first_name last_name updated_at]}})
        Look.includes(:user).all.zip(hashes) do |look, hash|
          expect(look.attributes).to eq(hash.except('user'))
          expect(look.user.attributes.slice(*%w[id email created_at])).to eq(hash['user'])
        end
      end
    end

    describe 'with proc option' do
      before :each do
        @looks = create_list :look, 3
      end

      it 'does not instantiate models' do
        expect(User).to_not receive(:instantiate)
        expect(Look).to_not receive(:instantiate)
        expect(Look.as_hashes(include: {user: {procs: {full_name: ->(h){ "#{h['first_name']} #{h['last_name']}"}}}}).size).to eq(3)
      end

      it 'returns hashes with virtual key' do
        hashes = Look.as_hashes(include: {user: {procs: {full_name: ->(h){ "#{h['first_name']} #{h['last_name']}"}}}})
        expect(hashes).to all have_keys('id', 'name', 'description', 'user', 'created_at', 'updated_at')
        expect(hashes.map{|h| h['user']}).to all have_keys('id', 'first_name', 'last_name', 'full_name')
      end

      it 'returns hashes with correct values' do
        hashes = Look.as_hashes(include: {user: {procs: {full_name: ->(h){ "#{h['first_name']} #{h['last_name']}"}}}})
        Look.includes(:user).zip(hashes) do |look, hash|
          expect(look.attributes).to eq(hash.except('user'))
          expect(look.user.attributes).to eq(hash['user'].except('full_name'))
          expect(hash['user']['full_name']).to eq("#{look.user.first_name} #{look.user.last_name}")
        end
      end
    end

    describe 'with sql alias' do
      before :each do
        @looks = create_list :look, 3
      end

      it 'does not instantiate models' do
        expect(Look).to_not receive(:instantiate)
        expect(User).to_not receive(:instantiate)
        expect(Look.as_hashes(include: {user: {only: [:id, "first_name || ' ' || last_name as full_name"]}}).size).to eq(3)
      end

      it 'returns hashes with virtual key' do
        hashes = Look.as_hashes(include: {user: {only: [:id, "first_name || ' ' || last_name as full_name"]}})
        expect(hashes).to all have_keys('id', 'name', 'description', 'user', 'created_at', 'updated_at')
        expect(hashes.map{|h| h['user']}).to all have_keys('id', 'full_name')
      end

      it 'returns hashes with correct values' do
        hashes = Look.as_hashes(include: {user: {only: [:id, "first_name || ' ' || last_name as full_name"]}})
        Look.includes(:user).zip(hashes) do |look, hash|
          expect(look.attributes).to eq(hash.except('user'))
          expect(look.user.attributes.slice('id', 'full_name')).to eq(hash['user'].except('full_name'))
          expect(hash['user']['full_name']).to eq("#{look.user.first_name} #{look.user.last_name}")
        end
      end
    end

    describe 'empty associations' do
      before :each do
        create_list :look, 3, user: nil
      end

      it 'returns nil when record does not exist' do
        expect(Look.as_hashes(include: :user)).to all include('user' => nil)
      end

      it 'returns nil when record does not exist with only option' do
        expect(Look.as_hashes(include: {user: {only: %i[id first_name]}})).to all include('user' => nil)
      end

      it 'returns nil when record does not exist with except option' do
        expect(Look.as_hashes(include: {user: {except: %i[created_at updated_at]}})).to all include('user' => nil)
      end

      it 'returns nil when record does not exist with procs option' do
        expect(Look.as_hashes(include: {user: {procs: {'some_attr' => ->(h){ 'string' }}}})).to all include('user' => nil)
      end
    end
  end

  describe 'as_structs' do

    describe 'without options' do
      before :each do
        @looks = create_list :look, 3
      end

      it 'does not instantiate models' do
        expect(Look).to_not receive(:instantiate)
        expect(User).to_not receive(:instantiate)
        expect(Look.as_structs(include: :user).size).to eq(3)
      end

      it 'returns structs with all keys' do
        structs = Look.as_structs(include: :user)
        expect(structs.map(&:to_h)).to all have_keys(*%i[id name description user created_at updated_at])
        expect(structs.map{|s| s.user.to_h}).to all have_keys(*%i[id first_name last_name email created_at updated_at])
      end

      it 'returns structs with correct values' do
        Look.includes(:user).all.zip(Look.as_structs(include: :user)) do |look, struct|
          expect(look.attributes.symbolize_keys).to eq(struct.to_h.except(:user))
          expect(look.user.attributes.symbolize_keys).to eq(struct.user.to_h)
        end
      end
    end

    describe 'with only option' do
      before :each do
        @looks = create_list :look, 3
      end

      it 'does not instantiate models' do
        expect(Look).to_not receive(:instantiate)
        expect(User).to_not receive(:instantiate)
        expect(Look.as_structs(include: {user: {only: %i[first_name last_name]}}).size).to eq(3)
      end

      it 'returns structs with selected keys' do
        structs = Look.as_structs(include: {user: {only: %i[id first_name]}})
        expect(structs.map(&:to_h)).to all have_keys(*%i[id name description user created_at updated_at])
        expect(structs.map{|s| s.user.to_h}).to all match({
          id: a_kind_of(Integer),
          first_name: a_kind_of(String)
        })
      end

      it 'returns structs with correct values' do
        structs = Look.as_structs(include: {user: {only: %i[id first_name created_at]}})
        Look.includes(:user).all.zip(structs) do |look, struct|
          expect(look.attributes.symbolize_keys).to eq(struct.to_h.except(:user))
          expect(look.user.attributes.slice(*%w[id first_name created_at]).symbolize_keys).to eq(struct.user.to_h)
        end
      end
    end

    describe 'with except option' do
      before :each do
        @looks = create_list :look, 3
      end

      it 'does not instantiate models' do
        expect(User).to_not receive(:instantiate)
        expect(Look).to_not receive(:instantiate)
        expect(Look.as_structs(include: {user: {except: %i[first_name last_name]}}).size).to eq(3)
      end

      it 'returns structs without excepted keys' do
        structs = Look.as_structs(include: {user: {except: %i[email created_at updated_at]}})
        expect(structs.map(&:to_h)).to all have_keys(*%i[id name description user created_at updated_at])
        expect(structs.map{|s| s.user.to_h}).to all match({
          id: a_kind_of(Integer),
          first_name: a_kind_of(String),
          last_name: a_kind_of(String)
        })
      end

      it 'returns structs with correct values' do
        structs = Look.as_structs(include: {user: {except: %i[first_name last_name updated_at]}})
        Look.includes(:user).all.zip(structs) do |look, struct|
          expect(look.attributes.symbolize_keys).to eq(struct.to_h.except(:user))
          expect(look.user.attributes.slice(*%w[id email created_at]).symbolize_keys).to eq(struct.user.to_h)
        end
      end
    end

    describe 'with proc option' do
      before :each do
        @looks = create_list :look, 3
      end

      it 'does not instantiate models' do
        expect(User).to_not receive(:instantiate)
        expect(Look).to_not receive(:instantiate)
        expect(Look.as_structs(include: {user: {procs: {full_name: ->(s){ "#{s.first_name} #{s.last_name}"}}}}).size).to eq(3)
      end

      it 'returns structs with virtual key' do
        structs = Look.as_structs(include: {user: {procs: {full_name: ->(s){ "#{s.first_name} #{s.last_name}"}}}})
        expect(structs.map(&:to_h)).to all have_keys(*%i[id name description user created_at updated_at])
        expect(structs.map{|s| s.user.to_h}).to all have_keys(*%i[id first_name last_name full_name])
      end

      it 'returns structs with correct values' do
        structs = Look.as_structs(include: {user: {procs: {full_name: ->(s){ "#{s.first_name} #{s.last_name}"}}}})
        Look.includes(:user).zip(structs) do |look, struct|
          expect(look.attributes.symbolize_keys).to eq(struct.to_h.except(:user))
          expect(look.user.attributes.symbolize_keys).to eq(struct.user.to_h.except(:full_name))
          expect(struct.user.full_name).to eq("#{look.user.first_name} #{look.user.last_name}")
        end
      end
    end

    describe 'with sql alias' do
      before :each do
        @looks = create_list :look, 3
      end

      it 'does not instantiate models' do
        expect(Look).to_not receive(:instantiate)
        expect(User).to_not receive(:instantiate)
        expect(Look.as_structs(include: {user: {only: [:id, "first_name || ' ' || last_name as full_name"]}}).size).to eq(3)
      end

      it 'returns structs with virtual key' do
        structs = Look.as_structs(include: {user: {only: [:id, "first_name || ' ' || last_name as full_name"]}})
        expect(structs.map(&:to_h)).to all have_keys(*%i[id name description user created_at updated_at])
        expect(structs.map{|s| s.user.to_h}).to all have_only_keys(*%i[id full_name])
      end

      it 'returns structs with correct values' do
        structs = Look.as_structs(include: {user: {only: [:id, "first_name || ' ' || last_name as full_name"]}})
        Look.includes(:user).zip(structs) do |look, struct|
          expect(look.attributes.symbolize_keys).to eq(struct.to_h.except(:user))
          expect(look.user.attributes.slice('id', 'full_name').symbolize_keys).to eq(struct.user.to_h.except(:full_name))
          expect(struct.user.full_name).to eq("#{look.user.first_name} #{look.user.last_name}")
        end
      end
    end

    describe 'empty associations' do
      before :each do
        create_list(:look, 3, user: nil)
      end

      it 'returns nil when when record does not exist' do
        expect(Look.as_structs(include: :user).map(&:to_h)).to all include(user: nil)
      end

      it 'returns nil when when record does not exist with only option' do
        expect(Look.as_structs(include: {user: {only: %i[id first_name]}}).map(&:to_h)).to all include(user: nil)
      end

      it 'returns nil when when record does not exist with except option' do
        expect(Look.as_structs(include: {user: {except: %i[created_at updated_at]}}).map(&:to_h)).to all include(user: nil)
      end

      it 'returns nil when when record does not exist with procs option' do
        expect(Look.as_structs(include: {user: {procs: {'some_attr' => ->(h){ 'string' }}}}).map(&:to_h)).to all include(user: nil)
      end
    end
  end


end