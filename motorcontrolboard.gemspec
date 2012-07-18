# -*- encoding: utf-8 -*-
require File.expand_path('../lib/motorcontrolboard/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Francesco Sacchi"]
  gem.email         = ["depsir@gmail.com"]
  gem.description   = %q{Interface library for MotorControlBoard board}
  gem.summary       = %q{}
  gem.homepage      = "http://irawiki.disco.unimib.it/irawiki/index.php/INFIND2011/12_Motor_control_board"

  gem.add_dependency('serialport', '>= 1.1.0')

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "motorcontrolboard"
  gem.require_paths = ["lib"]
  gem.version       = Motorcontrolboard::VERSION
end