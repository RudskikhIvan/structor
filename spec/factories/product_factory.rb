FactoryGirl.define do
  factory :product do
    name { FFaker::Product.product_name }
    description { FFaker::Lorem.paragraph }
    price { rand(10..90).to_f * 10 }
  end
end