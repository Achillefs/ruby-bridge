module Bridge
  class Deal
    attr_accessor :hands, :deck
  
    def initialize
      @hands = []
      @deck = Deck.new
      Direction.values.each do |dir|
        @hands[Direction.send(dir)] = Hand.new
      end
      deal!
      self
    end
    
    # deals one card per hand on a cycle until we run out of cards
    def deal!
      hands.cycle(deck.size/hands.size) { |hand| hand << deck.shift }
    end
    
    def to_page
      # returns HEX bridge book page value
    end
    
    def self.from_page
      # create deal and hands based on HEX bridge book page number
    end
    
    def method_missing(m, *args, &block)
      if hands.respond_to?(m)
        hands.send(m, *args, &block)
      else
        super
      end
    end
  end
end