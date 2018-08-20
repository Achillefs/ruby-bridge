module Bridge
  class DuplicateCallError < StandardError; end
  class InvalidCallError < StandardError; end
  class InvalidCallClassError < StandardError; end
  
  # The auction (bidding phase) of a game of bridge.
  class Auction
    attr_accessor :dealer, :calls, :contract
  
    # @param dealer: who distributes the cards and makes the first call.
    # @type dealer: Direction
    def initialize dealer
      self.dealer = dealer
      self.contract = nil
      self.calls = []
    end
  
    # Auction is complete if all players have called (ie. 4 or more calls)
    # and the last 3 calls are Pass calls.
    # @return: True if bidding is complete, False if not.
    # @rtype: bool
    def complete?
      passes = self.calls.last(3).select { |c| c.is_a?(Pass) }.size
      self.calls.size >= 4 and passes == 3
    end
  
    # Auction is passed out if each player has passed on their first turn.
    # In this case, the bidding is complete, but no contract is established.
    # @return: True if bidding is passed out, False if not.
    # @rtype: bool
    def passed_out?
      passes = calls.select { |c| c.is_a?(Pass) }.size
      self.calls.size == 4 and passes == 4
    end
    
    # When the bidding is complete, the contract is the last and highest
    # bid, which may be doubled or redoubled.
    # Hence, the contract represents the "final state" of the bidding.
    # @return: a dict containing the keywords:
    # @keyword bid: the last and highest bid.
    # @keyword declarer: the partner who first bid the contract strain.
    # @keyword doubleBy: the opponent who doubled the contract, or None.
    # @keyword redoubleBy: the partner who redoubled an opponent's double
    # on the contract, or None.
    def get_contract
      if self.complete? and not self.passed_out?
        bid = self.get_current_call(Bid)
        double = self.get_current_call(Double)
        redouble = self.get_current_call(Redouble)
        declarer_bid = nil
        # Determine partnership.
        caller = self.who_called?(bid)
        partnership = [caller, Direction[(caller + 2) % 4]]
        # Determine declarer.
        self.calls.each do |call|
          if call.is_a?(Bid) and call.strain == bid.strain and partnership.include?(self.who_called?(call))
            declarer_bid = call
            break
          end
        end
                  
        {
          :bid => bid,
          :declarer => declarer_bid.nil? ? nil : self.who_called?(declarer_bid),
          :double_by => double.nil? ? nil : self.who_called?(double),
          :redouble_by => redouble.nil? ? nil : self.who_called?(redouble) 
        }
      else
        nil  # Bidding passed out or not complete, no contract.
      end
    end
    
    # Appends call from position to the calls list.
    # Please note that call validity should be checked with isValidCall()
    # before calling this method!
    # @param call: a candidate call.
    def make_call call, player = nil
      assert_call(call.class)
      # Calls must be distinct.
      raise InvalidCallError, "#{call.inspect} is invalid" unless self.valid_call?(call)

      self.calls << call
      if self.complete? and not self.passed_out?
        self.contract = Contract.new(self)
      end
      true
    end

    # Check that call can be made, according to the rules of bidding.
    # @param call: the candidate call.
    # @param position: if specified, the position from which the call is made.
    # @return: True if call is available, False if not.
    def valid_call? call, position = nil
      # The bidding must not be complete.
      return false if complete?
    
      # Position's turn to play.
      return false if position and position != whose_turn
    
      # A pass is always available.
      return true if call.is_a?(Pass)
    
      # A bid must be greater than the current bid.
      if call.is_a?(Bid)
        return (!current_bid or call > current_bid)
      end
    
      # Doubles and redoubles only when a bid has been made.
      if current_bid
        bidder = who_called?(current_bid)
      
        # A double must be made on the current bid from opponents,
        # which has not been already doubled by partnership.
        if call.is_a?(Double)
          opposition = [Direction[(whose_turn + 1) % 4], Direction[(whose_turn + 3) % 4]]
          return (opposition.include?(bidder) and !current_double)
      
        # A redouble must be made on the current bid from partnership,
        # which has been doubled by an opponent.
        elsif call.is_a?(Redouble)
          partnership = [whose_turn, Direction[(whose_turn + 2) % 4]]
          return (partnership.include?(bidder) and current_double and !current_redouble)
        end
      end
    
      false  # Otherwise unavailable.
    end
  
    # Returns the position from which the specified call was made.
    # @param call: a call made in the auction.
    # @return: the position of the player who made call, or None.
    def who_called? call
      raise ArgumentError, "#{call.inspect} is not a call" unless call.is_a?(Call)
      return nil unless calls.include?(call) # Call not made by any player.
      Direction[(self.dealer + calls.find_index(call)) % 4]
    end
  
    # Returns the position from which the next call should be made.
    # @return: the next position to make a call, or None.
    def whose_turn
      return nil if complete?
      return Direction[(self.dealer + calls.size) % 4]
    end
  
    # Returns most recent current call of specified class, or None.
    # @param callclass: call class, in (Bid, Pass, Double, Redouble).
    # @return: most recent call matching type, or None.
    def get_current_call callclass
      assert_call(callclass)
      
      self.calls.reverse.each do |call|
        if call.is_a?(callclass)
          return call
        elsif call.is_a?(Bid)
          break  # Bids cancel all preceding calls.
        end
      end
      nil
    end
    
    def current_bid
      get_current_call(Bid)
    end
    
    def current_double
      get_current_call(Double)
    end
    
    def current_redouble
      get_current_call(Redouble)
    end
    
    def assert_call callclass
      raise InvalidCallClassError unless [Bid, Pass, Double, Redouble].include?(callclass)
    end
    
    def to_a
      self.calls
    end
  end
end