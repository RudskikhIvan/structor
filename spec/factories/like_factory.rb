FactoryGirl.define do
  factory :like do
    user { FactoryGirl.build(:user) }
    likeable { FactoryGirl.build(:product) }
  end
end