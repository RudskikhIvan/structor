FactoryGirl.define do
  factory :city do
    name { FFaker::Address.city }
    lat { FFaker::Geolocation.lat }
    lng { FFaker::Geolocation.lng }
  end
end