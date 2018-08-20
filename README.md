# Bridge

A lean mean bridge playing machine. Initially conceived and built in 2013, this is the heart of https://leobridge.net/

Large portions of this gem have been ported from [pybridge](http://sourceforge.net/projects/pybridge/)

Bridge is the bridge playing engine sitting behind [Leo Bridge](https://leobridge.net/) this is the first version initially built in 2013 and is shared here as a working game engine example. 

## Installation

Add this line to your application's Gemfile:

    #!ruby
    gem 'bridge'

And then execute:
    
    $ bundle

Or install it yourself as:

    $ gem install bridge

## Usage

You can have a look at `bin/leo-play` for an example of interaction with the Bridge::Game class (type `help` for available commands).


Here's a quick run-through:

    #!ruby
    require 'rubygems'  
    require 'bridge'
    include Bridge
    
    game = Game.new # start game
    players = [] # keep players somewhere handy
    Direction.each { |d| players[d] << game.add_player(d) }
    # you're ready to start playing


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request