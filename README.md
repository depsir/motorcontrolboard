# Motorcontrolboard

Interface library for MotorControlBoard board
http://irawiki.disco.unimib.it/irawiki/index.php/INFIND2011/12_Motor_control_board 

## Installation

Add this line to your application's Gemfile:

    gem 'motorcontrolboard'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install motorcontrolboard

## Usage

#!/usr/bin/env ruby
require 'motorcontrolboard'

#params for serial port
initParams = {  'port' => "/dev/ttyUSB0",
				'baud_rate' => 57600,
				'vidpid' => '10c4:ea60'}

@m = MotorControlBoard.new(initParams)
@m.initData('init.yaml')
@m.connect


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
