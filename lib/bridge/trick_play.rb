module Bridge
  # This class models the trick-taking phase of a game of bridge.
  # This code is generalised, and could easily be adapted to support a
  # variety of trick-taking card games.
  class TrickPlay
    attr_accessor :trumps, :declarer, :dummy, :lho, :rho, :played, :winners, :history
    
    # TODO: tricks, leader, winner properties?
    
    # @param declarer: the declarer from the auction.
    # @type declarer: Direction
    # @param trump_suit: the trump suit from the auction.
    # @type trump_suit: Suit or None      
    def initialize(declarer, trump_suit)
      raise TypeError, "Expected Direction, got #{declarer.inspect}" unless Direction[declarer]
      raise TypeError, "Expected Suit, got #{trump_suit.inspect}" if !trump_suit.nil? and Suit[trump_suit].nil?
      
      self.trumps = trump_suit
      self.declarer = declarer
      self.dummy = Direction[(declarer + 2) % 4]
      self.lho = Direction[(declarer + 1) % 4]
      self.rho = Direction[(declarer + 3) % 4]
      # Each trick corresponds to a cross-section of lists.
      self.played = {}
      self.history = []
      Direction.each do |position|
        self.played[position] = []
      end
      self.winners = []  # Winning player of each trick.
    end
    
    # Playing is complete if there are 13 complete tricks.
    # @return: True if playing is complete, False if not.
    def complete?
      self.winners.size == 13
    end
    
    # A trick is a set of cards, one from each player's hand.
    # The leader plays the first card, the others play in clockwise order.
    # @param: trick index, in range 0 to 12.
    # @return: a trick object.
    def get_trick(index)
      raise ArgumentError unless 0 <= index and index < 13
      if index == 0  # First trick.
        leader = self.lho  # Leader is declarer's left-hand opponent.
      else  # Leader is winner of previous trick.
        leader = self.winners[index - 1]
      end
      
      cards = []
      
      Direction.each do |position|
        # If length of list exceeds index value, player's card in trick.
        if self.played[position].size > index
          cards[position] = self.played[position][index]
        end
      end
      
      Trick.new(:leader => leader, :cards => cards)
    end

    # Returns the getTrick() tuple of the current trick.
    # @return: a (leader, cards) trick tuple.
    def get_current_trick
      # Index of current trick is length of longest played list minus 1.
      index = [0, (self.played.map { |dir,cards| cards.size }.max - 1)].max
      self.get_trick(index)
    end
    
    # Returns the number of tricks won by declarer/dummy and by defenders.
    # @return: the declarer trick count, the defender trick count.
    # @rtype: tuple
    def get_trick_count
      declarer_count, defender_count = 0, 0
      
      (0..self.winners.size-1).each do |i|
        trick = self.get_trick(i)
        winner = self.who_played?(self.winning_card(trick))
        if [self.declarer, self.dummy].include?(winner)
          declarer_count += 1
        else
          defender_count += 1
        end
      end
      
      [declarer_count, defender_count]
    end
    
    def get_tricks
      (0..self.winners.size-1).map do |i|
        self.get_trick(i)
      end
    end

    # Plays card to current trick.
    # Card validity should be checked with isValidPlay() beforehand.
    # @param card: the Card object to be played from player's hand.
    # @param player: the player of card, or None.
    # @param hand: the hand of player, or [].
    def play_card(card, player=nil, hand=nil)
      Bridge.assert_card(card)
      
      player = player || self.whose_turn
      hand = hand || [card]  # Skip hand check.
      
      raise ArgumentError, 'Not valid play' unless self.valid_play?(card, player, hand)
      self.played[player] << card
      self.history << card
      
      # If trick is complete, determine winner.
      trick = self.get_current_trick
      if trick.cards.compact.size == 4
        winner = self.who_played?(self.winning_card(trick))
        self.winners << winner
      end
      return true
    end

    # Card is playable if and only if:
    # - Play session is not complete.
    # - Direction is on turn to play.
    # - Card exists in hand.
    # - Card has not been previously played.
    # In addition, if the current trick has an established lead, then
    # card must follow lead suit OR hand must be void in lead suit.
    # Specification of player and hand are required for verification.
    def valid_play?(card, player=nil, hand=[])
      Bridge.assert_card(card)
      
      if self.complete?
        return false
      elsif hand and !hand.include?(card)
        return false  # Playing a card not in hand.
      elsif player and self.whose_turn != self.dummy and player != self.whose_turn
        return false  # Playing out of turn.
      elsif self.who_played?(card)
        return false  # Card played previously.
      end
      trick = self.get_current_trick
      # 0 if start of playing, 4 if complete trick.
      if [0, 4].include?(trick.cards.compact.size)
        return true # Card will be first in next trick.
      else # Current trick has an established lead: check for revoke.
        leadcard = trick.leader_card
        # Cards in hand that match suit of leadcard.
        followers = hand.select { |c| c.suit == leadcard.suit and !self.who_played?(c) }
        # Hand void in lead suit or card follows lead suit.
        return (followers.size == 0 or followers.include?(card))
      end
    end

    # Returns the player who played the specified card.
    # @param card: a Card.
    # @return: the player who played card.
    def who_played?(card)
      Bridge.assert_card(card) unless card.nil?
      self.played.each do |player,cards|
        return player if cards.include?(card)
      end
      false
    end

    # If playing is not complete, returns the player who is next to play.
    # @return: the player next to play.
    def whose_turn
      unless self.complete?
        trick = self.get_current_trick
        if trick.cards.compact.size == 4  # If trick is complete, trick winner's turn.
          return self.who_played?(self.winning_card(trick))
        else  # Otherwise, turn is next (clockwise) player in trick.
          return Direction[(trick.leader + trick.cards.compact.size) % 4]
        end
      end
      return false
    end
          
    # Determine which card wins the specified trick:
    # - In a trump contract, the highest ranked trump card wins.
    # - Otherwise, the highest ranked card of the lead suit wins.
    # @param: a complete (leader, cards) trick tuple.
    # @return: the Card object which wins the trick.
    def winning_card(trick)
      if trick.cards.compact.size == 4  # Trick is complete.
        if self.trumps  # Suit contract.
          trumpcards = trick.cards.compact.select { |c| c.suit_i == self.trumps }
          if trumpcards.size > 0 # Highest ranked trump.
            return trumpcards.max 
          else # we re in trump contract but play didn't have a trump.
            followers = trick.cards.compact.select { |c| c.suit == trick.leader_card.suit }
            return followers.max # Highest ranked card in lead suit.
          end
        else
          # No Trump contract, or no trump cards played.
          followers = trick.cards.compact.select { |c| c.suit == trick.leader_card.suit }
          return followers.max # Highest ranked card in lead suit.
        end
      else
        return false
      end
    end
    
    def to_a
      trick_counts = self.get_trick_count
      {
        trumps: self.trumps,
        declarer: self.declarer,
        dummy: self.dummy,
        lho: self.lho,
        rho: self.rho,
        played: self.played,
        winners: self.winners,
        declarer_trick_count: trick_counts.first,
        defender_trick_count: trick_counts.last,
        tricks: self.get_tricks
      }
    end
  end
end