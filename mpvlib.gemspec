# coding: utf-8
# lib = File.expand_path('../lib', __FILE__)
# $LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'mpvlib'
  spec.version       = '0.1'
  spec.authors       = ['John Labovitz']
  spec.email         = ['johnl@johnlabovitz.com']

  spec.summary       = %q{Ruby bindings to the MPV media player, via libmpv.}
  # spec.description   = %q{}
  spec.homepage      = 'http://github.com/jslabovitz/mpvlib'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split("\n").reject { |f| f.match(%r{^(test)/}) }
  spec.test_files    = `git ls-files -- test/*`.split("\n")
  spec.require_paths = ['lib']

  spec.add_dependency 'ffi'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'minitest-power_assert'
end