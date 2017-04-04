require_relative './spec_helper'
describe 'With the belongs to polymorphic associtation' do
  describe 'as_hashes' do

    let!(:product_likes){ create_list :like, 3, likeable: build(:product) }
    let!(:look_likes){ create_list :like, 3, likeable: build(:look) }
    let(:like_attributes){ %w[id user_id likeable_id likeable_type] }

    describe 'without options' do

      it 'does not instantiate models' do
        expect(Look).to_not receive(:instantiate)
        expect(Product).to_not receive(:instantiate)
        expect(Like).to_not receive(:instantiate)
        expect(Like.as_hashes(include: :likeable).size).to eq(6)
      end

      it 'returns hashes with correct types' do
        hashes = Like.as_hashes(include: :likeable)
        expect(hashes.select{|h| h['likeable_type'] == 'Look'}.size).to eq(3)
        expect(hashes.select{|h| h['likeable_type'] == 'Product'}.size).to eq(3)
      end

      it 'returns hashes with all keys' do
        hashes = Like.as_hashes(include: :likeable)
        expect(hashes).to all have_keys('id', 'user_id', 'likeable_id', 'likeable_type')

        expect(hashes.select{|h| h['likeable_type'] == 'Look'}.map{|h| h['likeable']})
            .to all have_keys('id', 'name', 'description', 'user_id', 'created_at', 'updated_at')
        expect(hashes.select{|h| h['likeable_type'] == 'Product'}.map{|h| h['likeable']})
            .to all have_keys('id', 'name', 'description', 'price', 'created_at', 'updated_at')
      end

      it 'returns hashes with correct values' do
        Like.includes(:likeable).all.zip(Like.as_hashes(include: :likeable)) do |like, hash|
          expect(like.attributes).to eq(hash.except('likeable'))
          expect(like.likeable.attributes).to eq(hash['likeable'])
        end
      end
    end

    describe 'with only option' do

      let :options do
        {
          include: {
            likeable: {
              look: {only: %i[name created_at]},
              product: {only: %i[id price]}
            }
          }
        }
      end

      it 'does not instantiate models' do
        expect(Product).to_not receive(:instantiate)
        expect(Look).to_not receive(:instantiate)
        expect(Like).to_not receive(:instantiate)
        expect(Like.as_hashes(options).size).to eq(6)
      end

      it 'returns hashes with correct model types' do
        hashes = Like.as_hashes(options)
        expect(hashes.select{|h| h['likeable_type'] == 'Look'}.size).to eq(3)
        expect(hashes.select{|h| h['likeable_type'] == 'Product'}.size).to eq(3)
      end

      it 'returns hashes with selected keys' do
        hashes = Like.as_hashes(options)
        expect(hashes).to all have_keys(*like_attributes)

        expect(hashes.select{|h| h['likeable_type'] == 'Look'}.map{|h| h['likeable']}).to all match({
          'id' => a_kind_of(Integer),
          'name' => a_kind_of(String),
          'created_at' => a_kind_of(Time)
        })

        expect(hashes.select{|h| h['likeable_type'] == 'Product'}.map{|h| h['likeable']}).to all match({
          'id' => a_kind_of(Integer),
          'price' => a_kind_of(BigDecimal)
        })
      end

      it 'returns hashes with correct values' do
        hashes = Like.as_hashes(options)
        Like.includes(:likeable).all.zip(hashes) do |like, hash|
          expect(like.attributes).to eq(hash.except('likeable'))
          attributes = like.likeable_type == 'Product' ? %w[id price] : %w[id name created_at]
          expect(like.likeable.attributes.slice(*attributes)).to eq(hash['likeable'])
        end
      end
    end

    describe 'with except option' do

      let :options do
        {
          include: {
            likeable: {
              look: {except: %i[user_id description updated_at]},
              product: {except: %i[description created_at updated_at]}
            }
          }
        }
      end

      it 'does not instantiate models' do
        expect(Product).to_not receive(:instantiate)
        expect(Look).to_not receive(:instantiate)
        expect(Like).to_not receive(:instantiate)
        expect(Like.as_hashes(options).size).to eq(6)
      end

      it 'returns hashes with correct model types' do
        hashes = Like.as_hashes(options)
        expect(hashes.select{|h| h['likeable_type'] == 'Look'}.size).to eq(3)
        expect(hashes.select{|h| h['likeable_type'] == 'Product'}.size).to eq(3)
      end

      it 'returns hashes with selected keys' do
        hashes = Like.as_hashes(options)
        expect(hashes).to all have_keys(*like_attributes)

        expect(hashes.select{|h| h['likeable_type'] == 'Look'}.map{|h| h['likeable']}).to all match({
          'id' => a_kind_of(Integer),
          'name' => a_kind_of(String),
          'created_at' => a_kind_of(Time)
        })

        expect(hashes.select{|h| h['likeable_type'] == 'Product'}.map{|h| h['likeable']}).to all match({
           'id' => a_kind_of(Integer),
           'name' => a_kind_of(String),
           'price' => a_kind_of(BigDecimal)
        })
      end

      it 'returns hashes with correct values' do
        hashes = Like.as_hashes(options)
        Like.includes(:likeable).all.zip(hashes) do |like, hash|
          expect(like.attributes).to eq(hash.except('likeable'))
          attributes = like.likeable_type == 'Product' ? %w[id name price] : %w[id name created_at]
          expect(like.likeable.attributes.slice(*attributes)).to eq(hash['likeable'])
        end
      end
    end

    describe 'with proc option' do

      let :options do
        {
            include: {
                likeable: {
                    look: {procs: {id_name: ->(h){ "#{h['id']}-#{h['name']}" }}},
                    product: {procs: {id_name: ->(h){ "#{h['id']}-#{h['name']}" }}}
                }
            }
        }
      end

      let(:product_attributes){ %w[id name description created_at updated_at id_name] }
      let(:look_attributes){ %w[id name description user_id created_at updated_at id_name] }

      it 'does not instantiate models' do
        expect(Product).to_not receive(:instantiate)
        expect(Look).to_not receive(:instantiate)
        expect(Like).to_not receive(:instantiate)
        expect(Like.as_hashes(options).size).to eq(6)
      end

      it 'returns hashes with correct model types' do
        hashes = Like.as_hashes(options)
        expect(hashes.select{|h| h['likeable_type'] == 'Look'}.size).to eq(3)
        expect(hashes.select{|h| h['likeable_type'] == 'Product'}.size).to eq(3)
      end

      it 'returns hashes with selected keys' do
        hashes = Like.as_hashes(options)
        expect(hashes).to all have_keys(*like_attributes)
        expect(hashes.select{|h| h['likeable_type'] == 'Look'}.map{|h| h['likeable']} ).to all have_keys(*look_attributes)
        expect(hashes.select{|h| h['likeable_type'] == 'Product'}.map{|h| h['likeable']} ).to all have_keys(*product_attributes)
      end

      it 'returns hashes with correct values' do
        hashes = Like.as_hashes(options)
        Like.includes(:likeable).all.zip(hashes) do |like, hash|
          expect(like.attributes).to eq(hash.except('likeable'))
          expect(like.likeable.attributes).to eq(hash['likeable'].except('id_name'))
          expect(hash['likeable']['id_name']).to eq("#{like.likeable.id}-#{like.likeable.name}")
        end
      end
    end

    describe 'with sql alias' do

      let :options do
        {
          include: {
            likeable: {
              look: {only: [:id, "id || '-' || name as id_name"]},
              product: {only: [:id, "id || '-' || name as id_name"]}
            }
          }
        }
      end

      let(:product_attributes){ %w[id id_name] }
      let(:look_attributes){ %w[id id_name] }

      it 'does not instantiate models' do
        expect(Product).to_not receive(:instantiate)
        expect(Look).to_not receive(:instantiate)
        expect(Like).to_not receive(:instantiate)
        expect(Like.as_hashes(options).size).to eq(6)
      end

      it 'returns hashes with correct model types' do
        hashes = Like.as_hashes(options)
        expect(hashes.select{|h| h['likeable_type'] == 'Look'}.size).to eq(3)
        expect(hashes.select{|h| h['likeable_type'] == 'Product'}.size).to eq(3)
      end

      it 'returns hashes with selected keys' do
        hashes = Like.as_hashes(options)
        expect(hashes).to all have_keys(*like_attributes)
        expect(hashes.select{|h| h['likeable_type'] == 'Look'}.map{|h| h['likeable']} ).to all have_keys(*look_attributes)
        expect(hashes.select{|h| h['likeable_type'] == 'Product'}.map{|h| h['likeable']} ).to all have_keys(*product_attributes)
      end

      it 'returns hashes with correct values' do
        hashes = Like.as_hashes(options)
        Like.includes(:likeable).all.zip(hashes) do |like, hash|
          expect(like.attributes).to eq(hash.except('likeable'))
          expect(like.likeable.attributes.slice(*%w(id))).to eq(hash['likeable'].except('id_name'))
          expect(hash['likeable']['id_name']).to eq("#{like.likeable.id}-#{like.likeable.name}")
        end
      end
    end

    describe 'empty associations' do

      let!(:product_likes){ create_list :like, 3, likeable: nil }
      let!(:look_likes){ create_list :like, 3, likeable: nil }

      it 'returns nil when there is not association' do
        expect(Like.as_hashes(include: :likeable)).to all include('likeable' => nil)
      end

      it 'returns only existed associations' do
        product_likes.each{|like| like.update(likeable: create(:product))}
        hashes = Like.as_hashes(include: :likeable)
        expect(hashes.select{|h| h['likeable_type'] == 'Product'}).to all include('likeable' => a_kind_of(Hash))
        expect(hashes.select{|h| h['likeable_type'] == 'Look'}).to all include('likeable' => nil)
      end

      let(:only_options) do
        {include: {likeable: {product: {only: %i[id name]}, look: {only: %i[id name]}}}}
      end

      it 'returns nil when there is not association with only option' do
        expect(Like.as_hashes(only_options)).to all include('likeable' => nil)
      end


      let(:except_options) do
        {include: {likeable: {product: {except: %i[id name]}, look: {except: %i[id name]}}}}
      end
      it 'returns nil when there is not association with except option' do
        expect(Like.as_hashes(except_options)).to all include('likeable' => nil)
      end


      let(:proc_options) do
        {include: {likeable: {
            product: {procs: {desc: ->(h){ h['description'] }}},
            look: {procs: {desc: ->(h){ h['description'] }}}
        }}}
      end
      it 'returns nil when there is not association with procs option' do
        expect(Like.as_hashes(proc_options)).to all include('likeable' => nil)
      end

    end

  end

  describe 'as_structs' do

    let!(:product_likes){ create_list :like, 3, likeable: build(:product) }
    let!(:look_likes){ create_list :like, 3, likeable: build(:look) }
    let(:like_attributes){ %w[id user_id likeable_id likeable_type] }

    describe 'without options' do

      it 'does not instantiate models' do
        expect(Look).to_not receive(:instantiate)
        expect(Product).to_not receive(:instantiate)
        expect(Like).to_not receive(:instantiate)
        expect(Like.as_structs(include: :likeable).size).to eq(6)
      end

      it 'returns structs with correct types' do
        structs = Like.as_structs(include: :likeable)
        expect(structs.select{|s| s.likeable_type == 'Look'}.size).to eq(3)
        expect(structs.select{|s| s.likeable_type == 'Product'}.size).to eq(3)
      end

      it 'returns structs with all keys' do
        structs = Like.as_structs(include: :likeable)
        expect(structs).to all respond_to_all('id', 'user_id', 'likeable_id', 'likeable_type')

        expect(structs.select{|s| s.likeable_type == 'Look'}.map{|s| s.likeable})
            .to all respond_to_all('id', 'name', 'description', 'user_id', 'created_at', 'updated_at')
        expect(structs.select{|s| s.likeable_type == 'Product'}.map{|s| s.likeable})
            .to all respond_to_all('id', 'name', 'description', 'price', 'created_at', 'updated_at')
      end

      it 'returns structs with correct values' do
        Like.includes(:likeable).all.zip(Like.as_structs(include: :likeable)) do |like, struct|
          expect(like).to have_attributes(struct.to_h.except(:likeable))
          expect(like.likeable).to have_attributes(struct.likeable.to_h)
        end
      end
    end

    describe 'with only option' do

      let :options do
        {
          include: {
            likeable: {
              look: {only: %i[name created_at]},
              product: {only: %i[id price]}
            }
          }
        }
      end

      it 'does not instantiate models' do
        expect(Product).to_not receive(:instantiate)
        expect(Look).to_not receive(:instantiate)
        expect(Like).to_not receive(:instantiate)
        expect(Like.as_structs(options).size).to eq(6)
      end

      it 'returns structs with correct model types' do
        structs = Like.as_structs(options)
        expect(structs.select{|s| s.likeable_type == 'Look'}.size).to eq(3)
        expect(structs.select{|s| s.likeable_type == 'Product'}.size).to eq(3)
      end

      it 'returns structs with selected keys' do
        structs = Like.as_structs(options)
        expect(structs).to all respond_to_all(*like_attributes)

        expect(structs.select{|s| s.likeable_type == 'Look'}.map{|s| s.likeable.to_h}).to all match({
          id: a_kind_of(Integer),
          name: a_kind_of(String),
          created_at: a_kind_of(Time)
        })

        expect(structs.select{|s| s.likeable_type == 'Product'}.map{|s| s.likeable.to_h}).to all match({
          id: a_kind_of(Integer),
          price: a_kind_of(BigDecimal)
        })
      end

      it 'returns structs with correct values' do
        structs = Like.as_structs(options)
        Like.includes(:likeable).all.zip(structs) do |like,struct|
          expect(like).to have_attributes(struct.to_h.except(:likeable))
          expect(like.likeable).to have_attributes(struct.likeable.to_h)
        end
      end
    end

    describe 'with except option' do

      let :options do
        {
          include: {
            likeable: {
              look: {except: %i[user_id description updated_at]},
              product: {except: %i[description created_at updated_at]}
            }
          }
        }
      end

      it 'does not instantiate models' do
        expect(Product).to_not receive(:instantiate)
        expect(Look).to_not receive(:instantiate)
        expect(Like).to_not receive(:instantiate)
        expect(Like.as_structs(options).size).to eq(6)
      end

      it 'returns structs with correct model types' do
        structs = Like.as_structs(options)
        expect(structs.select{|s| s.likeable_type == 'Look'}.size).to eq(3)
        expect(structs.select{|s| s.likeable_type == 'Product'}.size).to eq(3)
      end

      it 'returns structs with selected keys' do
        structs = Like.as_structs(options)
        expect(structs).to all respond_to_all(*like_attributes)

        expect(structs.select{|s| s.likeable_type == 'Look'}.map{|s| s.likeable.to_h}).to all match({
          id: a_kind_of(Integer),
          name: a_kind_of(String),
          created_at: a_kind_of(Time)
        })

        expect(structs.select{|s| s.likeable_type == 'Product'}.map{|s| s.likeable.to_h}).to all match({
          id: a_kind_of(Integer),
          name: a_kind_of(String),
          price: a_kind_of(BigDecimal)
        })
      end

      it 'returns structs with correct values' do
        structs = Like.as_structs(options)
        Like.includes(:likeable).all.zip(structs) do |like, struct|
          expect(like).to have_attributes(struct.to_h.except(:likeable))
          expect(like.likeable).to have_attributes(struct.likeable.to_h)
        end
      end
    end

    describe 'with proc option' do

      let :options do
        {
          include: {
            likeable: {
              look: {procs: {id_name: ->(h){ "#{h['id']}-#{h['name']}" }}},
              product: {procs: {id_name: ->(h){ "#{h['id']}-#{h['name']}" }}}
            }
          }
        }
      end

      let(:product_attributes){ %w[id name description created_at updated_at id_name] }
      let(:look_attributes){ %w[id name description user_id created_at updated_at id_name] }

      it 'does not instantiate models' do
        expect(Product).to_not receive(:instantiate)
        expect(Look).to_not receive(:instantiate)
        expect(Like).to_not receive(:instantiate)
        expect(Like.as_structs(options).size).to eq(6)
      end

      it 'returns structs with correct model types' do
        structs = Like.as_structs(options)
        expect(structs.select{|s| s.likeable_type == 'Look'}.size).to eq(3)
        expect(structs.select{|s| s.likeable_type == 'Product'}.size).to eq(3)
      end

      it 'returns structs with selected keys' do
        structs = Like.as_structs(options)
        expect(structs).to all respond_to_all(*like_attributes)
        expect(structs.select{|s| s.likeable_type == 'Look'}.map{|s| s.likeable}).to all respond_to_all(*look_attributes)
        expect(structs.select{|s| s.likeable_type == 'Product'}.map{|s| s.likeable}).to all respond_to_all(*product_attributes)
      end

      it 'returns structs with correct values' do
        structs = Like.as_structs(options)
        Like.includes(:likeable).all.zip(structs) do |like, struct|
          expect(like).to have_attributes(struct.to_h.except(:likeable))
          expect(like.likeable).to have_attributes(struct.likeable.to_h.except(:id_name))
          expect(struct.likeable.id_name).to eq("#{like.likeable.id}-#{like.likeable.name}")
        end
      end

    end

    describe 'with sql alias' do

      let :options do
        {
          include: {
            likeable: {
              look: {only: [:id, "id || '-' || name as id_name"]},
              product: {only: [:id, "id || '-' || name as id_name"]}
            }
          }
        }
      end

      let(:product_attributes){ %w[id id_name] }
      let(:look_attributes){ %w[id id_name] }

      it 'does not instantiate models' do
        expect(Product).to_not receive(:instantiate)
        expect(Look).to_not receive(:instantiate)
        expect(Like).to_not receive(:instantiate)
        expect(Like.as_structs(options).size).to eq(6)
      end

      it 'returns structs with correct model types' do
        structs = Like.as_structs(options)
        expect(structs.select{|s| s.likeable_type == 'Look'}.size).to eq(3)
        expect(structs.select{|s| s.likeable_type == 'Product'}.size).to eq(3)
      end

      it 'returns structs with selected keys' do
        structs = Like.as_structs(options)
        expect(structs).to all respond_to_all(*like_attributes)
        expect(structs.select{|s| s.likeable_type == 'Look'}.map{|s| s.likeable}).to all respond_to_all(*look_attributes)
        expect(structs.select{|s| s.likeable_type == 'Product'}.map{|s| s.likeable}).to all respond_to_all(*product_attributes)
      end

      it 'returns structs with correct values' do
        structs = Like.as_structs(options)
        Like.includes(:likeable).all.zip(structs) do |like, struct|
          expect(like).to have_attributes(struct.to_h.except(:likeable))
          expect(like.likeable).to have_attributes(struct.likeable.to_h.except(:id_name))
          expect(struct.likeable.id_name).to eq("#{like.likeable.id}-#{like.likeable.name}")
        end
      end
    end

    describe 'empty associations' do

      let!(:product_likes){ create_list :like, 3, likeable: nil }
      let!(:look_likes){ create_list :like, 3, likeable: nil }

      it 'returns nil when there is not association' do
        expect(Like.as_structs(include: :likeable)).to all have_attributes(likeable: nil)
      end

      it 'returns only existed associations' do
        product_likes.each{|like| like.update(likeable: create(:product))}
        structs = Like.as_structs(include: :likeable)
        expect(structs.select{|s| s.likeable_type == 'Product'}).to all have_attributes(likeable: a_kind_of(Struct))
        expect(structs.select{|s| s.likeable_type == 'Look'}).to all have_attributes(likeable: nil)
      end

      let(:only_options) do
        {include: {likeable: {product: {only: %i[id name]}, look: {only: %i[id name]}}}}
      end

      it 'returns nil when there is not association with only option' do
        expect(Like.as_structs(only_options)).to all have_attributes(likeable: nil)
      end


      let(:except_options) do
        {include: {likeable: {product: {except: %i[id name]}, look: {except: %i[id name]}}}}
      end
      it 'returns nil when there is not association with except option' do
        expect(Like.as_structs(except_options)).to all have_attributes(likeable: nil)
      end


      let(:proc_options) do
        {include: {likeable: {
            product: {procs: {desc: ->(s){ s.description }}},
            look: {procs: {desc: ->(s){ s.description }}}
        }}}
      end
      it 'returns nil when there is not association with procs option' do
        expect(Like.as_structs(proc_options)).to all have_attributes(likeable: nil)
      end

    end

  end

end