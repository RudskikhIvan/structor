require_relative './spec_helper'
describe 'With the has many associtation' do

  describe 'as_hashes' do

    describe 'without options' do
      before :each do
        3.times{ create(:user, looks: build_list(:look, 3)) }
      end

      it 'does not instantiate models' do
        expect(Look).to_not receive(:instantiate)
        expect(User).to_not receive(:instantiate)
        expect(User.as_hashes(include: :looks).size).to eq(3)
      end

      it 'returns hashes with all keys' do
        hashes = User.as_hashes(include: :looks)
        expect(hashes).to all have_keys('id', 'first_name', 'last_name', 'email', 'created_at', 'updated_at')
        expect(hashes.flat_map{|h| h['looks']}).to all have_keys('id', 'name', 'description', 'user_id', 'created_at', 'updated_at')
      end

      it 'returns hashes with correct values' do
        User.includes(:looks).all.zip(User.as_hashes(include: :looks)) do |user, hash|
          expect(user.attributes).to eq(hash.except('looks'))
          user.looks.zip(hash['looks']){|look, h| expect(look.attributes).to eq(h) }
        end
      end
    end

    describe 'with only option' do
      before :each do
        3.times{ create(:user, looks: build_list(:look, 3)) }
      end

      it 'does not instantiate models' do
        expect(Look).to_not receive(:instantiate)
        expect(User).to_not receive(:instantiate)
        expect(User.as_hashes(include: {looks: {only: %i[name created_at]}}).size).to eq(3)
      end

      it 'returns hashes with selected keys' do
        hashes = User.as_hashes(include: {looks: {only: %i[id name]}})
        expect(hashes).to all have_keys('id', 'first_name', 'last_name', 'email', 'created_at', 'updated_at')
        expect(hashes.flat_map{|h| h['looks']}).to all match({
          'id' => a_kind_of(Integer),
          'name' => a_kind_of(String),
          'user_id' => a_kind_of(Integer)
        })
      end

      it 'returns hashes with correct values' do
        hashes = User.as_hashes(include: {looks: {only: %i[id name created_at]}})
        User.includes(:looks).all.zip(hashes) do |user, hash|
          expect(user.attributes).to eq(hash.except('looks'))
          user.looks.zip(hash['looks']){|look, h| expect(look.attributes.slice('id', 'name', 'created_at', 'user_id')).to eq(h) }
        end
      end
    end

    describe 'with except option' do
      before :each do
        3.times{ create(:user, looks: build_list(:look, 3)) }
      end

      it 'does not instantiate models' do
        expect(User).to_not receive(:instantiate)
        expect(Look).to_not receive(:instantiate)
        expect(User.as_hashes(include: {looks: {except: %i[description]}}).size).to eq(3)
      end

      it 'returns hashes without excepted keys' do
        hashes = User.as_hashes(include: {looks: {except: %i[description created_at updated_at]}})
        expect(hashes).to all have_keys('id', 'first_name', 'last_name', 'email', 'created_at', 'updated_at')
        expect(hashes.flat_map{|h| h['looks']}).to all match({
          'id' => a_kind_of(Integer),
          'name' => a_kind_of(String),
          'user_id' => a_kind_of(Integer)
        })
      end

      it 'returns hashes with correct values' do
        hashes = User.as_hashes(include: {looks: {except: %i[description updated_at]}})
        User.includes(:looks).all.zip(hashes) do |user, hash|
          expect(user.attributes).to eq(hash.except('looks'))
          user.looks.zip(hash['looks']){|look, h| expect(look.attributes.slice('id', 'name', 'created_at', 'user_id')).to eq(h)}
        end
      end
    end

    describe 'with proc option' do
      before :each do
        3.times{ create(:user, looks: build_list(:look, 3)) }
      end

      it 'does not instantiate models' do
        expect(User).to_not receive(:instantiate)
        expect(Look).to_not receive(:instantiate)
        expect(User.as_hashes(include: {looks: {procs: {id_name: ->(h){ "#{h['id']} #{h['name']}"}}}}).size).to eq(3)
      end

      it 'returns hashes with virtual key' do
        hashes = User.as_hashes(include: {looks: {procs: {id_name: ->(h){ "#{h['id']} #{h['name']}"}}}})
        expect(hashes).to all have_keys('id', 'first_name', 'last_name', 'email', 'created_at', 'updated_at')
        expect(hashes.flat_map{|h| h['looks']}).to all have_keys('id', 'name', 'description', 'user_id', 'created_at', 'updated_at', 'id_name')
      end

      it 'returns hashes with correct values' do
        hashes = User.as_hashes(include: {looks: {procs: {id_name: ->(h){ "#{h['id']} #{h['name']}"}}}})
        User.includes(:looks).zip(hashes) do |user, hash|
          expect(user.attributes).to eq(hash.except('looks'))
          user.looks.zip(hash['looks']) do |look, h|
            expect(look.attributes).to eq(h.except('id_name'))
            expect("#{look.id} #{look.name}").to eq(h['id_name'])
          end
        end
      end
    end

    describe 'with sql alias' do
      before :each do
        3.times{ create(:user, looks: build_list(:look, 3)) }
      end

      it 'does not instantiate models' do
        expect(Look).to_not receive(:instantiate)
        expect(User).to_not receive(:instantiate)
        expect(User.as_hashes(include: {looks: {only: [:id, "id || ' ' || name as id_name"]}}).size).to eq(3)
      end

      it 'returns hashes with virtual key' do
        hashes = User.as_hashes(include: {looks: {only: [:id, "id || ' ' || name as id_name"]}})
        expect(hashes).to all have_keys('id', 'first_name', 'last_name', 'email', 'created_at', 'updated_at')
        expect(hashes.flat_map{|h| h['looks']}).to all have_keys('id', 'id_name', 'user_id')
      end

      it 'returns hashes with correct values' do
        hashes = User.as_hashes(include: {looks: {only: [:id, "id || ' ' || name as id_name"]}})
        User.includes(:looks).zip(hashes) do |user, hash|
          expect(user.attributes).to eq(hash.except('looks'))
          user.looks.zip(hash['looks']) do |look, h|
            expect(look.attributes.slice('id', 'user_id')).to eq(h.except('id_name'))
            expect("#{look.id} #{look.name}").to eq(h['id_name'])
          end
        end
      end
    end

    describe 'empty associations' do
      before :each do
        create_list(:user, 3)
      end

      it 'returns an empty array when collection is empty' do
        expect(User.as_hashes(include: :looks)).to all include('looks' => [])
      end

      it 'returns an empty array when collection is empty with only option' do
        expect(User.as_hashes(include: {looks: {only: %i[id name]}})).to all include('looks' => [])
      end

      it 'returns an empty array when collection is empty with except option' do
        expect(User.as_hashes(include: {looks: {except: %i[description]}})).to all include('looks' => [])
      end

      it 'returns an empty array when collection is empty with procs option' do
        expect(User.as_hashes(include: {looks: {procs: {'some_attr' => ->(h){ 'string' }}}})).to all include('looks' => [])
      end
    end
  end

  describe 'as_structs' do

    describe 'without options' do
      before :each do
        3.times{ create(:user, looks: build_list(:look, 3)) }
      end

      it 'does not instantiate models' do
        expect(Look).to_not receive(:instantiate)
        expect(User).to_not receive(:instantiate)
        expect(User.as_structs(include: :looks).size).to eq(3)
      end

      it 'returns structs with all keys' do
        structs = User.as_structs(include: :looks)
        expect(structs.map(&:to_h)).to all have_keys(*%i[id first_name last_name email created_at updated_at])
        expect(structs.flat_map{|s| s.looks.map(&:to_h)}).to all have_keys(*%i[id name description user_id created_at updated_at])
      end

      it 'returns structs with correct values' do
        User.includes(:looks).all.zip(User.as_structs(include: :looks)) do |user, struct|
          expect(user.attributes.symbolize_keys).to eq(struct.to_h.except(:looks))
          user.looks.zip(struct.looks){|look, s| expect(look.attributes.symbolize_keys).to eq(s.to_h) }
        end
      end
    end

    describe 'with only option' do
      before :each do
        3.times{ create(:user, looks: build_list(:look, 3)) }
      end

      it 'does not instantiate models' do
        expect(Look).to_not receive(:instantiate)
        expect(User).to_not receive(:instantiate)
        expect(User.as_structs(include: {looks: {only: %i[name created_at]}}).size).to eq(3)
      end

      it 'returns structs with selected keys' do
        structs = User.as_structs(include: {looks: {only: %i[id name]}})
        expect(structs.map(&:to_h)).to all have_keys(*%i[id first_name last_name email created_at updated_at])
        expect(structs.flat_map{|h| h.looks.map(&:to_h)}).to all match({
          id: a_kind_of(Integer),
          name: a_kind_of(String),
          user_id: a_kind_of(Integer)
        })
      end

      it 'returns structs with correct values' do
        structs = User.as_structs(include: {looks: {only: %i[id name created_at]}})
        User.includes(:looks).all.zip(structs) do |user, struct|
          expect(user.attributes.symbolize_keys).to eq(struct.to_h.except(:looks))
          user.looks.zip(struct.looks){|look, s|
            expect(look.attributes.slice('id', 'name', 'created_at', 'user_id').symbolize_keys).to eq(s.to_h) }
        end
      end
    end

    describe 'with except option' do
      before :each do
        3.times{ create(:user, looks: build_list(:look, 3)) }
      end

      it 'does not instantiate models' do
        expect(User).to_not receive(:instantiate)
        expect(Look).to_not receive(:instantiate)
        expect(User.as_structs(include: {looks: {except: %i[description]}}).size).to eq(3)
      end

      it 'returns structs without excepted keys' do
        structs = User.as_structs(include: {looks: {except: %i[description created_at updated_at]}})
        expect(structs.map(&:to_h)).to all have_keys(*%i[id first_name last_name email created_at updated_at])
        expect(structs.flat_map{|s| s.looks.map(&:to_h)}).to all match({
          id: a_kind_of(Integer),
          name: a_kind_of(String),
          user_id: a_kind_of(Integer)
        })
      end

      it 'returns structs with correct values' do
        structs = User.as_structs(include: {looks: {except: %i[description updated_at]}})
        User.includes(:looks).all.zip(structs) do |user, struct|
          expect(user.attributes.symbolize_keys).to eq(struct.to_h.except(:looks))
          user.looks.zip(struct.looks){|look, s|
            expect(look.attributes.slice('id', 'name', 'created_at', 'user_id').symbolize_keys).to eq(s.to_h)}
        end
      end
    end

    describe 'with proc option' do
      before :each do
        3.times{ create(:user, looks: build_list(:look, 3)) }
      end

      it 'does not instantiate models' do
        expect(User).to_not receive(:instantiate)
        expect(Look).to_not receive(:instantiate)
        expect(User.as_structs(include: {looks: {procs: {id_name: ->(h){ "#{h['id']} #{h['name']}"}}}}).size).to eq(3)
      end

      it 'returns structs with virtual key' do
        structs = User.as_structs(include: {looks: {procs: {id_name: ->(h){ "#{h['id']} #{h['name']}"}}}})
        expect(structs.map(&:to_h)).to all have_keys(*%i[id first_name last_name email created_at updated_at])
        expect(structs.flat_map{|s| s.looks.map(&:to_h)}).to all have_keys(*%i[id name description user_id created_at updated_at id_name])
      end

      it 'returns structs with correct values' do
        structs = User.as_structs(include: {looks: {procs: {id_name: ->(h){ "#{h['id']} #{h['name']}"}}}})
        User.includes(:looks).zip(structs) do |user, struct|
          expect(user.attributes.symbolize_keys).to eq(struct.to_h.except(:looks))
          user.looks.zip(struct.looks) do |look, s|
            expect(look.attributes.symbolize_keys).to eq(s.to_h.except(:id_name))
            expect("#{look.id} #{look.name}").to eq(s.id_name)
          end
        end
      end
    end

    describe 'with sql alias' do
      before :each do
        3.times{ create(:user, looks: build_list(:look, 3)) }
      end

      it 'does not instantiate models' do
        expect(Look).to_not receive(:instantiate)
        expect(User).to_not receive(:instantiate)
        expect(User.as_structs(include: {looks: {only: [:id, "id || ' ' || name as id_name"]}}).size).to eq(3)
      end

      it 'returns structs with virtual key' do
        structs = User.as_structs(include: {looks: {only: [:id, "id || ' ' || name as id_name"]}})
        expect(structs.map(&:to_h)).to all have_keys(*%i[id first_name last_name email created_at updated_at])
        expect(structs.flat_map{|h| h.looks.map(&:to_h)}).to all have_keys(*%i[id id_name user_id])
      end

      it 'returns structs with correct values' do
        structs = User.as_structs(include: {looks: {only: [:id, "id || ' ' || name as id_name"]}})
        User.includes(:looks).zip(structs) do |user, struct|
          expect(user.attributes.symbolize_keys).to eq(struct.to_h.except(:looks))
          user.looks.zip(struct.looks) do |look, s|
            expect(look.attributes.slice('id', 'user_id').symbolize_keys).to eq(s.to_h.except(:id_name))
            expect("#{look.id} #{look.name}").to eq(s.id_name)
          end
        end
      end
    end

    describe 'empty associations' do
      before :each do
        create_list(:user, 3)
      end

      it 'returns an empty array when collection is empty' do
        expect(User.as_structs(include: :looks).map(&:to_h)).to all include(looks: [])
      end

      it 'returns an empty array when collection is empty with only option' do
        expect(User.as_structs(include: {looks: {only: %i[id name]}}).map(&:to_h)).to all include(looks: [])
      end

      it 'returns an empty array when collection is empty with except option' do
        expect(User.as_structs(include: {looks: {except: %i[description]}}).map(&:to_h)).to all include(looks: [])
      end

      it 'returns an empty array when collection is empty with procs option' do
        expect(User.as_structs(include: {looks: {procs: {'some_attr' => ->(h){ 'string' }}}}).map(&:to_h)).to all include(looks: [])
      end
    end
  end

end