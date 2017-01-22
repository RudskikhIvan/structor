require_relative './spec_helper'
describe 'With the belongs_to associtation' do

  describe 'as_hashes' do

    it 'loads all fields with empty options' do
      @looks = create_list :look, 3
      expect(Look).to_not receive(:instantiate)
      expect(User).to_not receive(:instantiate)
      hashes = Look.as_hashes(include: :user)
      expect(hashes.size).to eq(3)
      expect(hashes).to all a_kind_of(Hash)
      expect(hashes).to all have_keys(*%w[id name user_id description created_at updated_at])
      expect(hashes).to all include('user' => {
        'id' => a_kind_of(Integer),
        'first_name' => a_kind_of(String),
        'last_name' => a_kind_of(String),
        'email' => a_kind_of(String),
        'created_at' => a_kind_of(Time),
        'updated_at' => a_kind_of(Time)
      })
    end

    it 'loads association correctly' do
      @looks = create_list :look, 3
      hashes = Look.as_hashes(include: :user)
      @looks.zip(hashes) do |look, hash|
        expect(look.id).to eq(hash['id'])
        expect(look.user_id).to eq(hash['user']['id'])
      end
    end

    it 'loads only selected fields' do
      @looks = create_list :look, 3
      hashes = Look.as_hashes(only: %i[id name], include: {user: {only: %i[id first_name created_at]}})
      expect(hashes.size).to eq(3)
      expect(hashes).to all match({
        'id' => a_kind_of(Integer),
        'name' => a_kind_of(String),
        'user_id' => a_kind_of(Integer),
        'user' => match({
          'id' => a_kind_of(Integer),
          'first_name' => a_kind_of(String),
          'created_at' => a_kind_of(Time)
        })
      })
    end

    it 'loads without excepted fields' do
      @looks = create_list :look, 3
      hashes = Look.as_hashes(except: %i[created_at updated_at], include: {user: {except: %i[email created_at updated_at]}})
      expect(hashes.size).to eq(3)
      expect(hashes).to all match({
        'id' => a_kind_of(Integer),
        'name' => a_kind_of(String),
        'user_id' => a_kind_of(Integer),
        'description' => a_kind_of(String),
        'user' => match({
          'id' => a_kind_of(Integer),
          'first_name' => a_kind_of(String),
          'last_name' => a_kind_of(String)
        })
      })
    end

    it 'applies procs' do
      @looks = create_list :look, 3
      hashes = Look.as_hashes(include: {
        user: {procs: {full_name: ->(h){ h.values_at('first_name', 'last_name').join(' ') }}}
      })
      hashes.each do |hash|
        expect(hash['user']['full_name']).to eq hash['user'].values_at('first_name', 'last_name').join(' ')
      end
    end

    it 'select field with sql alias' do
      @looks = create_list :look, 3
      hashes = Look.as_hashes(include: {user: {only: [:id, :first_name, :last_name, "first_name || ' ' || last_name as full_name"]}})
      expect(hashes.size).to eq(3)
      hashes.each do |hash|
        expect(hash['user']['full_name']).to eq("#{hash['user'].values_at('first_name','last_name').join(' ')}")
      end
    end

    it 'returns hashes with correct type of values' do
      @looks = create_list :look, 3
      hashes = Look.as_hashes(include: {user: {only: [:id, :first_name, :created_at]}})
      expect(hashes.size).to eq(3)
      expect(hashes).to all include({
        'user' => {
          'id' => a_kind_of(Integer),
          'first_name' => a_kind_of(String),
          'created_at' => a_kind_of(Time)
        }
      })
    end

  end

  describe 'as_structs' do

    it 'loads all fields with empty options' do
      @looks = create_list :look, 3
      expect(Look).to_not receive(:instantiate)
      expect(User).to_not receive(:instantiate)
      structs = Look.as_structs(include: :user)
      expect(structs.size).to eq(3)
      expect(structs).to all a_kind_of(Struct)
      expect(structs.map(&:to_h)).to all have_keys(*%i[id name user_id description created_at updated_at])
      expect(structs.map(&:user)).to all a_kind_of(Struct)
      expect(structs.map(&:user).map(&:to_h)).to all include({
        id: a_kind_of(Integer),
        first_name: a_kind_of(String),
        last_name: a_kind_of(String),
        email: a_kind_of(String),
        created_at: a_kind_of(Time),
        updated_at: a_kind_of(Time)
      })
    end

    it 'loads association correctly' do
      @looks = create_list :look, 3
      structs = Look.as_structs(include: :user)
      @looks.zip(structs) do |look, struct|
        expect(look.id).to eq(struct.id)
        expect(look.user_id).to eq(struct.user.id)
      end
    end

    it 'loads only selected fields' do
      @looks = create_list :look, 3
      structs = Look.as_structs(only: %i[id name], include: {user: {only: %i[id first_name created_at]}})
      expect(structs.size).to eq(3)
      expect(structs.map(&:to_h)).to all match({
        id: a_kind_of(Integer),
        name: a_kind_of(String),
        user_id: a_kind_of(Integer),
        user: a_kind_of(Struct)
      })
      expect(structs.map(&:user).map(&:to_h)).to all match({
        id: a_kind_of(Integer),
        first_name: a_kind_of(String),
        created_at: a_kind_of(Time)
      })
    end

    it 'loads without excepted fields' do
      @looks = create_list :look, 3
      structs = Look.as_structs(except: %i[created_at updated_at], include: {user: {except: %i[email created_at updated_at]}})
      expect(structs.size).to eq(3)
      expect(structs.map(&:to_h)).to all match({
        id: a_kind_of(Integer),
        name: a_kind_of(String),
        user_id: a_kind_of(Integer),
        description: a_kind_of(String),
        user: a_kind_of(Struct)
      })
      expect(structs.map(&:user).map(&:to_h)).to all match({
        id: a_kind_of(Integer),
        first_name: a_kind_of(String),
        last_name: a_kind_of(String)
      })
    end

    it 'applies procs' do
      @looks = create_list :look, 3
      structs = Look.as_structs(include: {
        user: {procs: {full_name: ->(s){ s.to_h.values_at(:first_name, :last_name).join(' ') }}}
      })
      structs.each do |struct|
        expect(struct.user.full_name).to eq struct.user.to_h.values_at(:first_name, :last_name).join(' ')
      end
    end

    it 'select field with sql alias' do
      @looks = create_list :look, 3
      structs = Look.as_structs(include: {user: {only: [:id, :first_name, :last_name, "first_name || ' ' || last_name as full_name"]}})
      expect(structs.size).to eq(3)
      structs.each do |struct|
        expect(struct.user.full_name).to eq("#{struct.user.to_h.values_at(:first_name, :last_name).join(' ')}")
      end
    end

    it 'returns structs with correct type of values' do
      @looks = create_list :look, 3
      structs = Look.as_structs(include: {user: {only: [:id, :first_name, :created_at]}})
      expect(structs.size).to eq(3)
      expect(structs.map(&:user).map(&:to_h)).to all match({
        id: a_kind_of(Integer),
        first_name: a_kind_of(String),
        created_at: a_kind_of(Time)
      })
    end

  end

end