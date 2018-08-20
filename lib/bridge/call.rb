module Bridge
  module Level
    extend Enum
    set_values :one, :two, :three, :four, :five, :six, :seven
  end
  
  module Suit
    extend Enum
    set_values :club, :diamond, :heart, :spade
  end
  
  module Rank
    extend Enum
    set_values :two, :three, :four, :five, :six, :seven, :eight, :nine, :ten, :jack, :queen, :king, :ace
  end
  
  module Strain
    extend Enum
    set_values :club, :diamond, :heart, :spade, :no_trump
  end
  
  class CallError < StandardError; end
  
  # Abstract class, inherited by Bid, Pass, Double and Redouble.
  class Call
    def self.from_string string
      string ||= ''
      call = nil
      case string.downcase
      when 'p','pass'
        call = Pass.new
      when 'd', 'double'
        call = Double.new
      when 'r', 'redouble'
        call = Redouble.new
      when /^bi?d? [a-z]{3,5} [a-z\s\_]{4,8}$/i
        bid = string.split
        bid.shift # get rid of 'bid'
        level = bid.shift
        strain = bid.join('_')
        call = Bid.new(level,strain)
      end
      raise CallError.new, "'#{string}' is not a call" if call.nil?
      call
    end
    
    def self.all
      calls = Strain.all.map { |s| Level.all.map { |l| Bid.new(l,s) } }.flatten
      calls << Double.new
      calls << Redouble.new
      calls << Pass.new
      calls
    end
    
    def to_s
      self.class.to_s.downcase.gsub('bridge::','')
    end
  end

  # A Bid represents a statement of a level and a strain.
  # @param level: the level of the bid.
  # @type level: L{Level}
  # @param strain: the strain (denomination) of the bid.
  # @type strain: L{Strain}
  class Bid < Call
    attr_accessor :level, :strain
    
    def initialize(level, strain)
      self.level  = level.is_a?(Integer)  ? level : Level.send(level.to_sym)
      self.strain = strain.is_a?(Integer) ? strain : Strain.send(strain.to_sym)
    end
    
    include Comparable
    def <=>(other)
      if other.is_a?(Bid) # Compare two bids.
        s_size = Strain.values.size
        # puts "#{self.level*s_size + self.strain} <=> #{other.level*s_size + other.strain}"
        (self.level*s_size + self.strain) <=> (other.level*s_size + other.strain)
      else # Comparing non-bid calls returns true.
        1
      end
    end
    
    def to_s
      "#{Level.name(level)} #{Strain.name(strain)}"
    end
  end

  # A Pass represents an abstention from the bidding.
  class Pass < Call; end

  # A Double over an opponent's current bid.
  class Double < Call; end
  
  # A Redouble over an opponent's double of partnership's current bid.
  class Redouble < Call; end
end