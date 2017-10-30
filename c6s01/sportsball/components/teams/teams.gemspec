
#coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "teams/version"

Gem::Specification.new do |spec|
  spec.name          = "teams"
  spec.version       = Teams::VERSION
  spec.authors       = ["Stephan Hagemann"]
  spec.email         = ["stephan.hagemann@gmail.com"]

  spec.summary       = %q{Teams Class}
  spec.description   = %q{Teams Class}

  # Prevent pushing this gem to RubyGems.org by setting allowed_push_host, or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = ""
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activemodel", "5.1.4"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end

