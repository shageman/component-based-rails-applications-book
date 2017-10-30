$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "app_component/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "app_component"
  s.version     = AppComponent::VERSION
  s.authors     = ["Stephan Hagemann"]
  s.email       = [""]
  s.summary     = "Summary of AppComponent."

  s.files = Dir["{app,config,db,lib}/**/*", "Rakefile", "README.md"]

  s.add_dependency "rails", "5.1.4"
  s.add_dependency "slim-rails", "3.1.3"
  s.add_dependency "trueskill"

  s.add_development_dependency "sqlite3"
end
