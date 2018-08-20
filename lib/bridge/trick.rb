module Bridge
  class Trick
    REQUIRED_CARDS = 4
    attr_accessor :cards
    attr_accessor :leader
    def initialize(params = {})
      params.map { |k,v| self.send(:"#{k}=",v) }
      self.cards = [] if self.cards.nil?
    end
    
    def done?
      self.cards.compact.size >= REQUIRED_CARDS
    end
    
    def leader_card
      self.cards[self.leader]
    end
    
    def method_missing(method, *args, &block)
      begin
        self.cards = self.cards.to_s.split(' ').map { |c| Card.from_string(c) } unless self.cards.class == Array
        self.cards.send(method, *args, &block)
      rescue Exception => e
        super
      end
    end
  end
end
