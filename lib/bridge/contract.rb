module Bridge
  class InvalidAuctionError < StandardError; end
  class Contract
    attr_accessor :redouble_by, :double_by, :bid, :declarer
    
    # @param auction: a completed, but not passed out, auction.
    # @type auction: Auction
    def initialize auction
      raise InvalidAuctionError unless auction.complete? and !auction.passed_out?
      # The contract is the last (and highest) bid.
      self.bid = auction.current_bid
      
      # The declarer is the first partner to bid the contract denomination.
      caller = auction.who_called?(self.bid)
      partnership = [caller, Direction[(caller + 2) % 4]]
      # Determine which partner is declarer.
      auction.calls.each do |call|
        if call.is_a?(Bid) and call.strain == self.bid.strain
          bidder = auction.who_called?(call)
          if partnership.include?(bidder)
            self.declarer = bidder
            break
          end
        end
      end

      self.double_by, self.redouble_by = [nil, nil]
      
      if auction.current_double
        # The opponent who doubled the contract bid.
        self.double_by = auction.who_called?(auction.current_double)
        if auction.current_redouble
          # The partner who redoubled an opponent's double.
          self.redouble_by = auction.who_called?(auction.current_redouble)
        end
      end
    end
    
    def to_hash
      {
        :bid => bid,
        :declarer => declarer,
        :double_by => double_by,
        :redouble_by => redouble_by
      }
    end
  end
end