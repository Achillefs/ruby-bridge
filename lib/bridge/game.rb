#require File.join(File.dirname(__FILE__),'result')

module Bridge
  class GameError < StandardError
  end

  # A bridge game sequences the auction and trick play.
  # The methods of this class comprise the interface of a state machine.
  # Clients should only use the class methods to interact with the game state.
  # Modifications to the state are typically made through BridgePlayer objects.
  # Methods which change the game state (make_call, playCard) require a player
  # argument as "authentication".
  class Game
    attr_accessor :auction, :play, :players, :options, :number
    attr_accessor :board, :board_queue, :results, :visible_hands
    attr_accessor :trump_suit, :result, :contract, :state
    attr_accessor :rubbers, :rubber_mode, :leonardo_mode
    
    def initialize opts = {}
      # Valid @positions (for Table).
      @positions = Direction.values

      # Mapping from Strain symbols (in auction) to Suit symbols (in play).
      @trump_map = {
        Strain.club => Suit.club, 
        Strain.diamond => Suit.diamond,
        Strain.heart => Suit.heart, 
        Strain.spade => Suit.spade,
        Strain.no_trump => nil
      }
      
      opts = {
        :auction => nil, 
        :play => nil,
        :players => {}, # One-to-one mapping from BridgePlayer to Direction
        :options => {},
        :board => nil, 
        :board_queue => [], # Boards for successive rounds.
        :results => [], # Results of previous rounds.
        :visible_hands => {}, # A subset of deal, containing revealed hands.
        :state => :new, 
        :rubber_mode => false
      }.merge(opts)
      
      opts.map { |k,v| self.send(:"#{k}=",v) if self.respond_to?(k) }
      
      if self.rubber_mode  # Use rubber scoring?
        self.rubbers = []  # Group results into Rubber objects.
      end
      
      self.contract = self.auction.nil? ? nil : self.auction.contract
      trump_suit = self.play.nil? ? nil : self.play.trump_suit
      result = self.in_progress? ? nil : self.results.last
    end

    # Implementation of ICardGame.
    # ref: https://pybridge.svn.sourceforge.net/svnroot/pybridge/trunk/pybridge/pybridge/interfaces/game.py
    def start! board = nil
      raise GameError, "Game in progress" if self.in_progress?

      if board  # Use specified board.
        self.board = board
      elsif !self.board_queue.empty?  # Use pre-specified board.
        self.board = self.board_queue.pop
      elsif self.board  # Advance to next round.
        self.board = self.board.next
      else  # Create an initial board.
        self.board = Board.first
      end
      
      if self.rubber_mode
        # Vulnerability determined by number of games won by each pair.
        if self.rubbers.size == 0 or self.rubbers.last.winner
          self.board.vulnerability = Vulnerability.none  # First round, new rubber.
        else
          pairs = self.rubbers.last.games.map { |game, pair| pair }
          
          if pairs.count([Direction.north, Direction.south]) > 0
            if pairs.count([Direction.east, Direction.west]) > 0
              self.board.vulnerability = Vulnerability.all
            else
              self.board.vulnerability = Vulnerability.north_south
            end
          else
            if pairs.count([Direction.east, Direction.west]) > 0
              self.board.vulnerability = Vulnerability.east_west
            else
              self.board.vulnerability = Vulnerability.none
            end
          end
        end # if self.rubbers.size == 0 or self.rubbers[-1].winner
      end # if self.rubber_mode
      self.auction = Auction.new(self.board.dealer)  # Start auction.
      self.play = nil
      self.visible_hands.clear

      # Remove deal from board, so it does not appear to clients.
      visible_board = self.board.copy
      visible_board.deal = self.visible_hands
      
      self.state = :auction
      true
    end
    
    def in_play?
      if !self.play.nil?
        !self.play.complete?
      else
        false
      end
    end
    
    def in_auction?
      if !self.auction.nil?
        !self.auction.passed_out?
      else
        false
      end
    end

    def in_progress?
      if !self.play.nil?
        !self.play.complete?
      elsif !self.auction.nil?
        !self.auction.passed_out?
      else
        false
      end
    end

    def next_game_ready?
      !self.in_progress? and self.players.size == 4
    end

    def get_state
      state = {}
      
      state[:options] = self.options
      state[:results] = self.results
      state[:state] = self.state
      state[:contract] = self.contract
      state[:calls] = Call.all
      state[:available_calls] = []
      begin
        state[:turn] = self.get_turn
      rescue Exception => e
        state[:turn] = nil
      end
      
      if self.in_progress?
        if state[:state] == :auction
          state[:available_calls] = Call.all.select { |c| self.auction.valid_call?(c) }.compact
        end
        # Remove hidden hands from deal.
        visible_board = self.board.copy
        visible_board.deal = self.visible_hands
        state[:board] = visible_board
      end
      
      state[:auction] = self.auction.to_a unless self.auction.nil?
      state[:play] = self.play.to_a unless self.play.nil?
      
      state
    end

    def add_player(position)
      raise TypeError, "Expected valid Direction, got #{position}" unless Direction[position]
      raise GameError, "Position #{position} is taken" if self.players.values.include?(position)
      
      player = Player.new(self)
      self.players[player] = position

      return player
    end

    def remove_player(position)
      raise TypeError, "Expected valid Direction, got #{position}" unless Direction[position]
      raise GameError, "Position #{position} is vacant" unless self.players.values.include?(position)
      
      self.players.reject! { |player,pos| pos == position }
    end
    
    # Send undo message to either auction or trick play
    # this is only available while there is an auction or trick_play
    def undo!
      case self.state
      when :auction
        if self.auction.complete?
          false # can't undo if auction is complete yo.
        else
          card = self.auction.calls.pop # remove the last undo
          if card
            true
          else
            false
          end
        end
      when :playing
        # remove the last card from everywhere
        card = self.play.history.pop
        if card
          trick = self.play.get_current_trick
          player = self.play.who_played?(card)
          # this was a completed trick, we need to remove it from the winner queue
          if trick.cards.compact.size == 4
            winner = self.play.who_played?(self.play.winning_card(trick))
            self.play.winners.pop if self.play.winners.last == winner
          end
          self.play.get_current_trick.cards.delete(card)
          self.play.played.each { |k,h| h.delete(card) }
          self.board.deal.hands[player] << card
          true
        else
          false          
        end
      else
        false
      end
    end

    # Bridge-specific methods.
  
    # Make a call in the current auction.
    # This method expects to receive either a player argument or a position.
    # If both are given, the position argument is disregarded.
    # @param call: a Call object.
    # @type call: Bid or Pass or Double or Redouble
    # @param player: if specified, a player object.
    # @type player: BridgePlayer or nil
    # @param position: if specified, the position of the player making call.
    # @type position: Direction or nil
    def make_call(call, player=nil, position=nil)
      raise TypeError, "Expected Call, got #{call}" unless [Bid, Pass, Double, Redouble].include?(call.class)
        
      if player
        raise GameError, "Player unknown to this game" unless self.players.include?(player)
        position = self.players[player]
      end
      
      raise TypeError, "Expected Direction, got #{position.class}" if position.nil? or Direction[position].nil?
      
      # Validate call according to game state.
      raise GameError, "No game in progress" if self.auction.nil?
      raise GameError, "Auction complete" if self.auction.complete?
      raise GameError, "Call made out of turn" if self.get_turn != position
      raise GameError, "Call cannot be made" unless self.auction.valid_call?(call, position)

      self.auction.make_call(call)
      
      if self.auction.complete? and !self.auction.passed_out?
        self.state = :playing
        self.contract = self.auction.get_contract
        trump_suit = @trump_map[self.contract[:bid].strain]
        self.play = TrickPlay.new(self.contract[:declarer], trump_suit)
      elsif self.auction.passed_out?
        self.state = :finished
      end
      
      # If bidding is passed out, game is complete.
      self._add_result(self.board, contract=nil) if not self.in_progress? and self.board.deal

      if !self.in_progress? and self.board.deal
        # Reveal all unrevealed hands.
        Direction.each do |position|
          hand = self.board.deal.hands[position]
          self.reveal_hand(hand, position) if hand and !self.visible_hands.include?(position)
        end
      end
    end
    
    def signal_alert(alert, position)
      pass  # TODO
    end

    # Play a card in the current play session.
    # This method expects to receive either a player argument or a position.
    # If both are given, the position argument is disregarded.
    # If position is specified, it must be that of the player of the card:
    # declarer plays cards from dummy's hand when it is dummy's turn.
    # @param card: a Card object.
    # @type card: Card
    # @param player: if specified, a player object.
    # @type player: BridgePlayer or nil
    # @param position: if specified, the position of the player of the card.
    # @type position: Direction or nil
    def play_card(card, player=nil, position=nil)
      Bridge.assert_card(card)
        
      if player
        raise GameError, "Invalid player reference" unless self.players.include?(player)
        position = self.players[player]
      end
      
      raise TypeError, "Expected Direction, got #{position}" unless Direction[position]
      raise GameError, "No game in progress, or play complete" if self.play.nil? or self.play.complete?

      playfrom = position

      # Declarer controls dummy's turn.
      if self.get_turn == self.play.dummy
        if self.play.declarer == position
          playfrom = self.play.dummy  # Declarer can play from dummy.
        elsif self.play.dummy == position
          raise GameError, "Dummy cannot play hand"
        end
      end
      
      raise GameError, "Card played out of turn" if self.get_turn != playfrom
      
      hand = self.board.deal[playfrom] || []
      # If complete deal known, validate card play.
      if self.board.deal.size == Direction.size
        unless self.play.valid_play?(card, position, hand)
          raise GameError, "Card #{card} cannot be played from hand"
        end
      end
      
      self.play.play_card(card)
      hand.delete(card)
      
      # Dummy's hand is revealed when the first card of first trick is played.
      if self.play.get_trick(0).cards.compact.size == 1
        dummyhand = self.board.deal[self.play.dummy]
        # Reveal hand only if known.
        self.reveal_hand(dummyhand, self.play.dummy) if dummyhand
      end

      # If play is complete, game is complete.
      if !self.in_progress? and self.board.deal
        self.state = :finished
        tricks_made, _ = self.play.get_trick_count
        self._add_result(self.board, self.contract, tricks_made)
      end

      if !self.in_progress? and self.board.deal
        # Reveal all unrevealed hands.
        Direction.each do |position|
          hand = self.board.deal[position]
          if hand and !self.visible_hands.include?(position)
            self.reveal_hand(hand, position)
          end
        end
      end
      
      true
    end
    
    def _add_result(board, contract=nil, tricks_made=nil, opts = {})
      if self.rubber_mode
        result = RubberResult.new(board, contract, tricks_made, opts)
        if self.rubbers.size > 0 and self.rubbers[-1].winner.nil?
          rubber = self.rubbers[-1]
        else   # Instantiate new rubber.
          rubber = Rubber()
          self.rubbers << rubber
          rubber << result
        end
      elsif self.leonardo_mode
        result = LeonardoResult.new(board, contract, tricks_made, opts)
      else
        result = DuplicateResult.new(board, contract, tricks_made, opts)
      end
      
      self.results << result
    end
    
    # Reveal hand to all observers.
    # @param hand: a hand of Card objects.
    # @type hand: list
    # @param position: the position of the hand.
    # @type position: Direction
    def reveal_hand(hand, position)
      raise TypeError, "Expected Direction, got #{position}" unless Direction[position]
      
      self.visible_hands[position] = hand
      # Add hand to board only if it was previously unknown.
      self.board.deal.hands[position] = hand unless self.board.deal.hands[position]
    end

    # If specified hand is visible, returns the list of cards in hand.
    # @param position: the position of the requested hand.
    # @type position: Direction
    # @return: the hand of player at position.
    def get_hand(position)
      raise TypeError, "Expected Direction, got #{position}" unless Direction[position]

      if self.board and self.board.deal.hands[position]
        self.board.deal.hands[position]
      else
        raise GameError, "Hand unknown"
      end
    end

    def get_turn
      if self.in_progress?
        if self.auction.complete?  # In trick play.
          self.play.whose_turn
        else  # Currently in the auction.
          self.auction.whose_turn
        end
      else  # Not in game.
        raise GameError, "No game in progress"
      end
    end
    
    def claim direction, tricks
      if self.in_progress?
        if self.auction.complete?  # In trick play.
          self.state = :finished
          declarer_tricks, defender_tricks = self.play.get_trick_count
          _add_result(self.board, self.contract, declarer_tricks, claim: [direction, tricks, defender_tricks])
        else  # Currently in the auction.
          raise GameError, "Cannot claim during auction"
        end
      else  # Not in game.
        raise GameError, "No game in progress"
      end
    end
  end
end