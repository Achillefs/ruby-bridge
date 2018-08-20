module Bridge
  class Hand
    attr_accessor :cards, :played, :current
  
    def initialize
      self.cards = []
    end
  
    def method_missing(m, *args, &block)
      if cards.respond_to?(m)
        cards.send(m, *args, &block)
      else
        super
      end
    end
  
    def to_s
      cards.map(&:to_s).join(' ')
    end
    
    def to_json opts = {}
      cards.to_json
    end
  end
end