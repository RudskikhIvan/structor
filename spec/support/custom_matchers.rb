RSpec::Matchers.define :have_keys do |*keys|
  match do |actual|
    (keys - actual.keys).empty?
  end
  description do
    "have keys: #{keys.join(', ')}"
  end
end

RSpec::Matchers.define :have_only_keys do |*keys|
  match do |actual|
    (keys & actual.keys) == keys
  end
  description do
    "have only keys: #{keys.join(', ')}"
  end
end

RSpec::Matchers.define :a_kind_of_boolean do
  match do |actual|
    actual == true or actual == false
  end
  description do
    "be true or false"
  end
end