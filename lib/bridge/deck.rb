require 'securerandom'

module Bridge
  class Deck
    attr_accessor :cards
  
    def initialize
      @cards = Card::RANKS.product(Card::SUITS).map { |a| Card.new(a[0],a[1]) }
      @cards.shuffle!(random: SecureRandom)
    end
    
    # make sure shuffling is as random as possible
    def shuffle!
      @cards.shuffle!(random: SecureRandom)
    end
    
    def shuffle
      @cards.shuffle(random: SecureRandom)
    end
    
    def inspect
      cards.inspect
    end
  
    def method_missing(method, *args, &block)
      begin
        @cards.send(method, *args, &block)
      rescue Exception => e
        super
      end
    end
  end
end