FactoryGirl.define do
  factory :address do
    user { FactoryGirl.build(:user) }
    address { FFaker::Address.street_address }
    city { FFaker::Address.city }
    zip_code { FFaker::AddressUS.zip_code }
    approved { rand(2) == 1 }
  end
end