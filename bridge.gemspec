# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bridge/version'

Gem::Specification.new do |spec|
  spec.name          = "leonardo-bridge"
  spec.version       = Bridge::VERSION
  spec.authors       = ["Achilles Charmpilas"]
  spec.email         = ["achilles@clickitmedia.eu"]
  spec.description   = %q{A lean mean bridge playing machine}
  spec.summary       = %q{Encapsulates all the necessary logic that allows 4 players to play a bridge game. Also supports rubber scoring.}
  spec.homepage      = "https://leobridge.net"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  spec.add_dependency "nutrun-string"
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "simplecov"
end
