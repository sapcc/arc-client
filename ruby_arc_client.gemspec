# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'arc_client/version'

Gem::Specification.new do |spec|
  spec.name          = "arc-client"
  spec.version       = ArcClient::VERSION
  spec.authors       = ["Arturo Reuschenbach Puncernau"]
  spec.email         = ["a.reuschenbach.puncernau@sap.com"]

  spec.summary       = %q{Ruby client to use the Arc API}
  spec.description   = %q{Ruby client to use the Arc API}
  spec.homepage      = "https://github.com/sapcc/arc-client.git"
  spec.license       = "Apache 2"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency 'pry', '~> 0.10.3'
  spec.add_dependency "rest-client", '~> 2.0.0.rc3'
end
