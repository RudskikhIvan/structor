require_relative './spec_helper'
describe 'StructToHash' do

  before :each do
    create_list :user, 3
  end

  describe 'as_hashes' do

    it('User class respond_to as_hashes'){ expect(User).to respond_to(:as_hashes) }
    it('User scope respond_to as_hashes'){ expect(User.all).to respond_to(:as_hashes) }

  end

end