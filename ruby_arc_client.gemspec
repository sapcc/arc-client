# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ruby_arc_client/version'

Gem::Specification.new do |spec|
  spec.name          = "ruby-arc-client"
  spec.version       = RubyArcClient::VERSION
  spec.authors       = ["Arturo Reuschenbach Puncernau"]
  spec.email         = ["a.reuschenbach.puncernau@sap.com"]

  spec.summary       = %q{Ruby client to use the Arc API}
  spec.description   = %q{Ruby client to use the Arc API}
  spec.homepage      = "https://github.com/pages/monsoon/arc/"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  # else
  #   raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  # end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_dependency "rest-client", "~> 1.8"
end
