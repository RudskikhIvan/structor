require_relative './spec_helper'
describe 'Without Associations' do

  describe 'as_hashes' do

    it('User class respond_to as_hashes'){ expect(User).to respond_to(:as_hashes) }
    it('User scope respond_to as_hashes'){ expect(User.all).to respond_to(:as_hashes) }

    describe 'without options' do
      before :each do
        @users = create_list :user, 3
      end

      it 'does not instantiate models' do
        expect(User).to_not receive(:instantiate)
        expect(User.as_hashes.size).to eq(3)
      end

      it 'returns hashes with all keys' do
        expect(User.as_hashes).to all have_keys('id', 'first_name', 'last_name', 'email', 'created_at', 'updated_at')
      end

      it 'returns hashes with correct values' do
        User.all.zip(User.as_hashes) do |user, hash|
          expect(user.attributes).to eq(hash)
        end
      end
    end

    describe 'with only option' do
      before :each do
        @users = create_list :user, 3
      end

      it 'does not instantiate models' do
        expect(User).to_not receive(:instantiate)
        expect(User.as_hashes(only: %i[first_name last_name]).size).to eq(3)
      end

      it 'returns hashes with selected keys' do
        expect(User.as_hashes(only: %i[id first_name])).to all match({
          'id' => a_kind_of(Integer),
          'first_name' => a_kind_of(String)
        })
      end

      it 'returns hashes with correct values' do
        User.all.zip(User.as_hashes(only: %i[id first_name created_at])) do |user, hash|
          expect(user.attributes.slice(*%w[id first_name created_at])).to eq(hash)
        end
      end
    end

    describe 'with except option' do
      before :each do
        @users = create_list :user, 3
      end

      it 'does not instantiate models' do
        expect(User).to_not receive(:instantiate)
        expect(User.as_hashes(except: %i[first_name last_name]).size).to eq(3)
      end

      it 'returns hashes without excepted keys' do
        expect(User.as_hashes(except: %i[email created_at updated_at])).to all match({
           'id' => a_kind_of(Integer),
           'first_name' => a_kind_of(String),
           'last_name' => a_kind_of(String)
        })
      end

      it 'returns hashes with correct values' do
        User.all.zip(User.as_hashes(except: %i[first_name last_name updated_at])) do |user, hash|
          expect(user.attributes.slice(*%w[id email created_at])).to eq(hash)
        end
      end
    end

    describe 'with proc option' do
      before :each do
        @users = create_list :user, 3
      end

      it 'does not instantiate models' do
        expect(User).to_not receive(:instantiate)
        expect(User.as_hashes(procs: {full_name: ->(h){ "#{h['first_name']} #{h['last_name']}"}}).size).to eq(3)
      end

      it 'returns hashes virtual key' do
        expect(User.as_hashes(except: %i[email created_at updated_at],
                              procs: {full_name: ->(h){ "#{h['first_name']} #{h['last_name']}"}})).to all match({
          'id' => a_kind_of(Integer),
          'first_name' => a_kind_of(String),
          'last_name' => a_kind_of(String),
          'full_name' => a_kind_of(String)
        })
      end

      it 'returns hashes with correct values' do
        User.all.zip(User.as_hashes(procs: {full_name: ->(h){ "#{h['first_name']} #{h['last_name']}"}})) do |user, hash|
          expect(user.attributes).to eq(hash.except('full_name'))
          expect(hash['full_name']).to eq("#{user.first_name} #{user.last_name}")
        end
      end
    end

    describe 'with sql alias' do
      before :each do
        @users = create_list :user, 3
      end

      it 'does not instantiate models' do
        expect(User).to_not receive(:instantiate)
        expect(User.as_hashes(only: [:id, "first_name || ' ' || last_name as full_name"]).size).to eq(3)
      end

      it 'returns hashes without excepted keys' do
        expect(User.as_hashes(only: [:id, "first_name || ' ' || last_name as full_name"])).to all match({
          'id' => a_kind_of(Integer),
          'full_name' => a_kind_of(String)
        })
      end

      it 'returns hashes with correct values' do
        User.all.zip(User.as_hashes(only: [:id, "first_name || ' ' || last_name as full_name"])) do |user, hash|
          expect(user.id).to eq(hash['id'])
          expect(hash['full_name']).to eq("#{user.first_name} #{user.last_name}")
        end
      end
    end
  end

  describe 'as_structs' do

    it('User class respond_to as_structs'){ expect(User).to respond_to(:as_structs) }
    it('User scope respond_to as_structs'){ expect(User.all).to respond_to(:as_structs) }

    describe 'without options' do
      before :each do
        @users = create_list :user, 3
      end

      it 'does not instantiate models' do
        expect(User).to_not receive(:instantiate)
        expect(User.as_structs.size).to eq(3)
      end

      it 'returns structs with all keys' do
        expect(User.as_structs.map(&:to_h)).to all have_keys(*%i[id first_name last_name email created_at updated_at])
      end

      it 'returns structs with correct values' do
        User.all.zip(User.as_structs) do |user, struct|
          expect(user.attributes.symbolize_keys).to eq(struct.to_h)
        end
      end
    end

    describe 'with only option' do
      before :each do
        @users = create_list :user, 3
      end

      it 'does not instantiate models' do
        expect(User).to_not receive(:instantiate)
        expect(User.as_structs(only: %i[first_name last_name]).size).to eq(3)
      end

      it 'returns structs with selected keys' do
        expect(User.as_structs(only: %i[id first_name]).map(&:to_h)).to all match({
          id: a_kind_of(Integer),
          first_name: a_kind_of(String)
        })
      end

      it 'returns structs with correct values' do
        User.all.zip(User.as_structs(only: %i[id first_name created_at])) do |user, struct|
          expect(user.attributes.slice(*%w[id first_name created_at])).to eq(struct.to_h.stringify_keys)
        end
      end
    end

    describe 'with except option' do
      before :each do
        @users = create_list :user, 3
      end

      it 'does not instantiate models' do
        expect(User).to_not receive(:instantiate)
        expect(User.as_structs(except: %i[first_name last_name]).size).to eq(3)
      end

      it 'returns structs without excepted keys' do
        expect(User.as_structs(except: %i[email created_at updated_at]).map(&:to_h)).to all match({
          id: a_kind_of(Integer),
          first_name: a_kind_of(String),
          last_name: a_kind_of(String)
        })
      end

      it 'returns structs with correct values' do
        User.all.zip(User.as_structs(except: %i[first_name last_name updated_at])) do |user, struct|
          expect(user.attributes.slice(*%w[id email created_at])).to eq(struct.to_h.stringify_keys)
        end
      end
    end

    describe 'with proc option' do
      before :each do
        @users = create_list :user, 3
      end

      it 'does not instantiate models' do
        expect(User).to_not receive(:instantiate)
        expect(User.as_structs(procs: {full_name: ->(s){ "#{s.first_name} #{s.last_name}"}}).size).to eq(3)
      end

      it 'returns structs virtual key' do
        expect(User.as_structs(procs: {full_name: ->(s){ "#{s.first_name} #{s.last_name}"}}).map(&:to_h)).to all include({
          full_name: a_kind_of(String)
        })
      end

      it 'returns structs with correct values' do
        User.all.zip(User.as_structs(procs: {full_name: ->(s){ "#{s.first_name} #{s.last_name}"}})) do |user, struct|
          expect(user.attributes.symbolize_keys).to eq(struct.to_h.except(:full_name))
          expect(struct.full_name).to eq("#{user.first_name} #{user.last_name}")
        end
      end
    end

    describe 'with sql alias' do
      before :each do
        @users = create_list :user, 3
      end

      it 'does not instantiate models' do
        expect(User).to_not receive(:instantiate)
        expect(User.as_structs(only: [:id, "first_name || ' ' || last_name as full_name"]).size).to eq(3)
      end

      it 'returns structs without excepted keys' do
        expect(User.as_structs(only: [:id, "first_name || ' ' || last_name as full_name"]).map(&:to_h)).to all match({
          id: a_kind_of(Integer),
          full_name: a_kind_of(String)
        })
      end

      it 'returns structs with correct values' do
        User.all.zip(User.as_structs(only: [:id, "first_name || ' ' || last_name as full_name"])) do |user, struct|
          expect(user.id).to eq(struct.id)
          expect(struct.full_name).to eq("#{user.first_name} #{user.last_name}")
        end
      end
    end

  end

end