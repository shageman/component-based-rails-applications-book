
$:.push File.expand_path("../lib", __FILE__)

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "teams_store"
  s.version     = "0.0.1"
  s.authors     = ["Your name"]
  s.email       = ["Your email"]
  s.summary     = "Summary of TeamsStore."
  s.description = "Description of TeamsStore."

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "teams"

  s.add_development_dependency "rspec"
end

