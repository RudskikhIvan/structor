FactoryGirl.define do
  factory :look do
    name { FFaker::Lorem.word.downcase }
    description { FFaker::Lorem.paragraph }
    user { FactoryGirl.build(:user) }
    products { FactoryGirl.build_list(:product, rand(2..3)) }
  end
end