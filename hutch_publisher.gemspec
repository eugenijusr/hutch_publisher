$:.unshift(File.join(File.dirname(__FILE__), 'lib'))

Gem::Specification.new do |spec|
  spec.name          = 'hutch_publisher'
  spec.version       = '0.1.0'
  spec.authors       = ['Eugenijus Radlinskas']
  spec.email         = ['eugene@bitlabs.com']
  spec.summary       = 'Hutch Publisher'
  spec.description   = 'Thread safe publisher for Hutch'
  spec.homepage      = 'https://github.com/bit-labs/hutch_publisher'
  spec.license       = 'MIT'
  spec.files         = `git ls-files`.split("\n")
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'hutch', '~> 0.19.0'
  spec.add_dependency 'connection_pool', '~> 2.0.0'
end
