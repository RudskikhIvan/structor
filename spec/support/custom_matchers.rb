RSpec::Matchers.define :have_keys do |*keys|
  match do |actual|
    (keys - actual.keys).empty?
  end
  description do
    "have keys: #{keys.join(', ')}"
  end
end