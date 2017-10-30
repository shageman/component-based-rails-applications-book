
# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "predictor"
  spec.version       = "0.1.0"
  spec.authors       = ["Stephan Hagemann"]
  spec.email         = ["stephan.hagemann@gmail.com"]

  spec.summary       = %q{Prediction Core}

  spec.files = Dir["{lib}/**/*", "Rakefile", "README.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "trueskill"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end

