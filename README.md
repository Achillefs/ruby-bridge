# Bridge
Bridge is the bridge playing engine sitting behind [Leo Bridge](https://leobridge.net/) this is the first version initially built in 2013 and is shared here as a working game engine example. 

You can use it to experiment with building a card game UI, or however else you wish. 

Large portions of this gem have been ported from [pybridge](http://sourceforge.net/projects/pybridge/)

## Installation

Add this line to your application's Gemfile:

    #!ruby
    gem 'leonardo-bridge', require: 'bridge'

And then execute:
    
    $ bundle

Or install it yourself as:

    $ gem install leonardo-bridge

## Usage

You can have a look at `bin/leo-play` for an example of interaction with the Bridge::Game class (type `help` for available commands).

IF you clone the source, you can also run `./bin/leo-play` to try out a rudimentary interactive game (meant as a demo, this is NOT a full bridge game).


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
