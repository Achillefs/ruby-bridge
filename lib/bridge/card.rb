module Bridge
  class CardError < ArgumentError; end
  
  class Card
    include Comparable
    
    RANKS = %w(2 3 4 5 6 7 8 9 10 J Q K A)
    SUITS = %w(C D H S)
    
    def initialize(rank, suit)
      raise CardError.new "'#{rank}' is not a card rank" unless RANKS.include?(rank)
      raise CardError.new "'#{suit}' is not a card suit" unless SUITS.include?(suit)
      @rank = rank
      @suit = suit
    end
    attr_reader :rank, :suit
    
    def <=>(other)
      # this ordering sorts first by rank, then by suit
      (Card::SUITS.find_index(self.suit) <=> Card::SUITS.find_index(other.suit)).nonzero? or
        (Card::RANKS.find_index(self.rank) <=> Card::RANKS.find_index(other.rank))
    end
 
    def to_s
      @rank + @suit
    end
  
    def honour
      case rank
      when 'J'
        1
      when 'Q'
        2
      when 'K'
        3
      when 'A'
        4
      else
        0
      end
    end
    
    def suit_i
      SUITS.index(suit)
    end
    
    def self.from_string string
      raise CardError.new, "'#{string}' is not a card" if string.size < 2
      suit = string[string.size-1]
      rank = string.chop
      new(rank.upcase, suit.upcase)
    end
  end
end
