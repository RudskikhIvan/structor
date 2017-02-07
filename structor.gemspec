$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "structor/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "structor"
  s.version     = Structor::VERSION
  s.authors     = ["Rudskikh Ivan"]
  s.email       = ["shredder.rull@gmail.com"]
  s.homepage    = "https://github.com/shredder-rull/structor"
  s.summary     = "Extend ActiveRecord to load records as structs or hashes avoid instantiation."
  s.description = "Extend ActiveRecord to load records as structs or hashes avoid instantiation"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "activerecord", "~> 5.0.0"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "benchmark-memory"
  s.add_development_dependency "rspec", "~> 3.5"
  s.add_development_dependency "factory_girl"
  s.add_development_dependency "ffaker"
  s.add_development_dependency "database_cleaner"
  s.add_development_dependency "pry"
end
