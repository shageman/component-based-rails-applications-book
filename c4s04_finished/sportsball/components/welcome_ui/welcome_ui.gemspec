$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "welcome_ui/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "welcome_ui"
  s.version     = WelcomeUi::VERSION
  s.authors     = ["Stephan Hagemann"]
  s.email       = ["Write your email address"]
  s.summary     = "Summary of WelcomeUi."

  s.files = Dir["{app,config,db,lib}/**/*", "Rakefile", "README.md"]

  s.add_dependency "rails", "5.1.4"
  s.add_dependency "slim-rails", "3.1.3"
  s.add_dependency "jquery-rails", "4.3.1"

  s.add_dependency "app_component"

  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "rails-controller-testing"


  s.add_development_dependency "sqlite3"
end
