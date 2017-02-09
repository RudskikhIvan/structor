FactoryGirl.define do
  factory :address do
    user { FactoryGirl.build(:user) }
    address { FFaker::Address.street_address }
    city { FactoryGirl.build(:city) }
    zip_code { FFaker::AddressUS.zip_code }
    approved { rand(2) == 1 }
  end
end