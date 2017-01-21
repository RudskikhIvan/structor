require_relative './spec_helper'
describe 'StructToHash' do

  describe 'as_hashes' do

    it('User class respond_to as_hashes'){ expect(User).to respond_to(:as_hashes) }
    it('User scope respond_to as_hashes'){ expect(User.all).to respond_to(:as_hashes) }

    it 'loads all fields with empty options' do
      @users = create_list :user, 3
      expect(User).to_not receive(:instantiate)
      hashes = User.as_hashes
      expect(hashes.size).to eq(3)
      expect(hashes).to all a_kind_of(Hash)
      expect(hashes).to all have_key('id')
      expect(hashes).to all have_key('first_name')
      expect(hashes).to all have_key('last_name')
      expect(hashes).to all have_key('email')
      expect(hashes).to all have_key('created_at')
      expect(hashes).to all have_key('updated_at')
    end

    it 'loads only selected fields' do
      @users = create_list :user, 3
      expect(User).to_not receive(:instantiate)
      hashes = User.as_hashes(only: %i[id first_name])
      expect(hashes.size).to eq(3)
      expect(hashes).to all a_kind_of(Hash)
      expect(hashes).to all match({
        'id' => a_kind_of(Integer),
        'first_name' => a_kind_of(String)
      })
    end

    it 'loads without excepted fields' do
      @users = create_list :user, 3
      hashes = User.as_hashes(except: %i[created_at updated_at email])
      expect(hashes.size).to eq(3)
      expect(hashes).to all a_kind_of(Hash)
      expect(hashes).to all match({
        'id' => a_kind_of(Integer),
        'first_name' => a_kind_of(String),
        'last_name' => a_kind_of(String)
      })
    end

    it 'applies procs' do
      @users = create_list :user, 3
      expect(User).to_not receive(:instantiate)
      hashes = User.as_hashes(only: %i[id first_name last_name],
                              procs: {full_name: ->(h){ "#{h['first_name']} #{h['last_name']}"}})
      expect(hashes).to all a_kind_of(Hash)
      expect(hashes).to all have_key('full_name')
      hashes.each do |hash|
        expect(hash['full_name']).to eq("#{hash['first_name']} #{hash['last_name']}")
      end
    end

    it 'select field with sql alias' do
      @users = create_list :user, 3
      hashes = User.as_hashes(only: [:id, :first_name, :last_name, "first_name || ' ' || last_name as full_name"])
      expect(hashes).to all a_kind_of(Hash)
      expect(hashes).to all have_key('full_name')
      hashes.each do |hash|
        expect(hash['full_name']).to eq("#{hash['first_name']} #{hash['last_name']}")
      end
    end

    it 'returns hashes with correct type of values' do
      @users = create_list :user, 3
      hashes = User.as_hashes(only: [:id, :first_name, :created_at])
      expect(hashes).to all match({
        'id' => a_kind_of(Integer),
        'first_name' => a_kind_of(String),
        'created_at' => a_kind_of(Time)
      })
    end


  end

  describe 'as_structs' do

    it('User class respond_to as_structs'){ expect(User).to respond_to(:as_structs) }
    it('User scope respond_to as_structs'){ expect(User.all).to respond_to(:as_structs) }

    it 'loads all fields with empty options' do
      @users = create_list :user, 3
      expect(User).to_not receive(:instantiate)
      structs = User.as_structs
      expect(structs.size).to eq(3)
      expect(structs).to all a_kind_of(Struct)
      expect(structs).to all respond_to('id')
      expect(structs).to all respond_to('first_name')
      expect(structs).to all respond_to('last_name')
      expect(structs).to all respond_to('email')
      expect(structs).to all respond_to('created_at')
      expect(structs).to all respond_to('updated_at')
    end

    it 'loads only selected fields' do
      @users = create_list :user, 3
      structs = User.as_structs(only: %i[id first_name])
      expect(structs.size).to eq(3)
      expect(structs).to all a_kind_of(Struct)
      expect(structs.map(&:to_h)).to all match({
        id: a_kind_of(Integer),
        first_name: a_kind_of(String)
      })
    end

    it 'loads without excepted fields' do
      @users = create_list :user, 3
      structs = User.as_structs(except: %i[created_at updated_at email])
      expect(structs.size).to eq(3)
      expect(structs).to all a_kind_of(Struct)
      expect(structs.map(&:to_h)).to all match({
        id: a_kind_of(Integer),
        first_name: a_kind_of(String),
        last_name: a_kind_of(String)
      })
    end

    it 'applies procs' do
      @users = create_list :user, 3
      expect(User).to_not receive(:instantiate)
      structs = User.as_structs(only: %i[id first_name last_name],
                              procs: {full_name: ->(st){ "#{st.first_name} #{st.last_name}"}})
      expect(structs).to all a_kind_of(Struct)
      expect(structs).to all respond_to('full_name')
      structs.each do |st|
        expect(st.full_name).to eq("#{st.first_name} #{st.last_name}")
      end
    end

    it 'select field with sql alias' do
      @users = create_list :user, 3
      expect(User).to_not receive(:instantiate)
      structs = User.as_structs(only: [:id, :first_name, :last_name, "first_name || ' ' || last_name as full_name"])
      expect(structs).to all a_kind_of(Struct)
      expect(structs).to all respond_to('full_name')
      structs.each do |st|
        expect(st.full_name).to eq("#{st.first_name} #{st.last_name}")
      end
    end
  end

end