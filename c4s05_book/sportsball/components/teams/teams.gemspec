$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "teams/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "teams"
  s.version     = Teams::VERSION
  s.authors     = ["Stephan Hagemann"]
  s.email       = ["Write your email address"]
  s.summary     = "Summary of Teams."

  s.files = Dir["{app,config,db,lib}/**/*", "Rakefile", "README.md"]

  s.add_dependency "activerecord", "5.1.4"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "shoulda-matchers"
  s.add_development_dependency "database_cleaner"

  s.add_development_dependency "sqlite3"
end
