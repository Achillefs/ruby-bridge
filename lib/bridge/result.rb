
module Bridge
  class Result
    VULN_MAP = {
      Vulnerability.none => [],
      Vulnerability.north_south => [Direction.north, Direction.south],
      Vulnerability.east_west => [Direction.east, Direction.west],
      Vulnerability.all => [
        Direction.north, Direction.east,
        Direction.west, Direction.south
      ]
    }
    
    def _get_score
      raise NoMethodError  # Expected to be implemented by subclasses.
    end

    # @type board: Board
    # @type contract: Contract
    # @type tricks_made: int or None
    attr_accessor :board, :contract, :tricks_made, :is_vulnerable, :score
    attr_accessor :is_doubled, :is_redoubled, :is_vulnerable, :is_major,
      :contract_level, :tricks_made, :tricks_required, :trump_suit, :claimed, :claimed_by
    
    def initialize(board, contract, tricks_made = nil, opts = {})
      self.board = board
      self.contract = contract
      self.tricks_made = tricks_made
      
      # a claim has been made. Let's modify the trick count accordingly
      if opts[:claim].is_a?(Array)
        self.claimed_by = opts[:claim][0]
        self.claimed = opts[:claim][1]
        defender_tricks = opts[:claim][2]
        if [self.contract[:declarer],(self.contract[:declarer] + 2) % 4].include?(claimed_by)
          self.tricks_made += claimed # if declarer claimed, add claim to tally
        else # if defender claimed, add what remains to tally
          self.tricks_made = 13 - (defender_tricks + claimed)
        end
        self.tricks_made
      end
      
      self.is_vulnerable = nil
      if self.contract
        vuln = self.board.vulnerability || Vulnerability.none
        self.is_vulnerable = VULN_MAP[vuln].include?(self.contract[:declarer])
      end
      
      self.score = self._get_score
    end

    # Compute the component values which contribute to the score.
    # Note that particular scoring schemes may ignore some of the components.
    # Scoring values: http://en.wikipedia.org/wiki/Bridge_scoring
    # @return: a dict of component values.
    # @rtype: dict
    def _get_score_components
      components = {}

      self.is_doubled      = self.contract[:double_by] ? true : false
      self.is_redoubled    = self.contract[:redouble_by] ? true : false
      self.contract_level  = self.contract[:bid].level + 1
      self.tricks_required = contract_level + 6
      self.trump_suit      = self.contract[:bid].strain
      self.is_major        = [Strain.spade, Strain.heart].include?(self.contract[:bid].strain)
      
      if tricks_made >= tricks_required  # Contract successful.
        #### Contract tricks (bid and made) ####
        if is_major || self.contract[:bid].strain == Strain.no_trump # Hearts, Spades and NT score 30 for each odd trick.
          components['odd'] = contract_level * 30
          if trump_suit == Strain.no_trump
            components['odd'] += 10  # For NT, add a 10 point bonus.
          end
        else
          components['odd'] = contract_level * 20
        end
        
        if is_redoubled
          components['odd'] *= 4  # Double the doubled score.
        elsif is_doubled
          components['odd'] *= 2  # Double score.
        end


        #### over_tricks ####
        over_tricks = tricks_made - tricks_required
        
        if is_redoubled
          # 400 for each overtrick if vulnerable, 200 if not.
          if is_vulnerable
            components['over'] = over_tricks * 400
          else
            components['over'] = over_tricks * 200
          end
        elsif is_doubled
          # 200 for each overtrick if vulnerable, 100 if not.
          if is_vulnerable
            components['over'] = over_tricks * 200
          else
            components['over'] = over_tricks * 100
          end
        else  # Undoubled contract.
          if is_major || self.contract[:bid].strain == Strain.no_trump
            # Hearts, Spades and NT score 30 for each overtrick.
            components['over'] = over_tricks * 30
          else
            # Clubs and Diamonds score 20 for each overtrick.
            components['over'] = over_tricks * 20
          end
        end

        #### Premium bonuses ####

        if tricks_required == 13
          # 1500 for grand slam if vulnerable, 1000 if not.
          if is_vulnerable
            components['slambonus'] = 1500
          else
            components['slambonus'] = 1000
          end
        elsif tricks_required == 12
          # 750 for small slam if vulnerable, 500 if not.
          if is_vulnerable
            components['slambonus'] = 750
          else
            components['slambonus'] = 500
          end
        end
        
        if components['odd'] >= 100 # Game contract (non-slam).
          # 500 for game if vulnerable, 300 if not.
          if is_vulnerable
            components['gamebonus'] = 500
          else
            components['gamebonus'] = 300
          end
        else # Non-game contract.
          components['partscore'] = 50
        end
        
        #### Insult bonus ####
        if is_redoubled
          components['insultbonus'] = 100
        elsif is_doubled
          components['insultbonus'] = 50
        end
      else  # Contract not successful.
        under_tricks = tricks_required - tricks_made
        if is_redoubled
          if is_vulnerable
            # -400 for first, then -600 each.
            components['under'] = -400 + (under_tricks - 1) * -600
          else
            # -200 for first, -400 for second and third, then -600 each.
            components['under'] = -200 + (under_tricks - 1) * -400
            if under_tricks > 3
              components['under'] += (under_tricks - 3) * -200
            end
          end
        elsif is_doubled
          if is_vulnerable
            # -200 for first, then -300 each.
            components['under'] = -200 + (under_tricks - 1) * -300
          else
            # -100 for first, -200 for second and third, then -300 each.
            components['under'] = -100 + (under_tricks - 1) * -200
            if under_tricks > 3
              components['under'] += (under_tricks - 3) * -100
            end
          end
        else
          if is_vulnerable
            # -100 each.
            components['under'] = under_tricks * -100
          else
            # -50 each.
            components['under'] = under_tricks * -50
          end
        end
      end
      components
    end
    
    def to_a
      { 
        score: _get_score,
        tricks_made: tricks_made,
        tricks_required: tricks_required,
        contract_level: contract_level,
        trump_suit: trump_suit,
        vulnerable: is_vulnerable,
        major: is_major,
        doubled: is_doubled,
        redoubled: is_redoubled,
        claimed: claimed,
        claimed_by: claimed_by
      }
    end
  end


#Represents the result of a completed round of duplicate bridge.
  class DuplicateResult < Result
    # Duplicate bridge scoring scheme.
    # @return: score value: positive for declarer, negative for defenders.
    def _get_score
      score = 0
      if self.contract and self.tricks_made
        self._get_score_components.each do |key, value|
          if ['odd', 'over', 'under', 'slambonus', 'gamebonus', 'partscore', 'insultbonus'].include?(key)
            score += value
          end
        end
      end
      score
    end
  end
  
  # Represents the result of a completed round of rubber bridge.
  class RubberResult < Result
    # Rubber bridge scoring scheme.
    # @return: 2-tuple of numeric scores (above the line, below the line): positive for
    # declarer, negative for defenders.
    def _get_score
      above, below = 0, 0
      if self.contract and self.tricks_made
        self._get_score_components.items.each do |key, value|
          # Note: gamebonus/partscore are not assigned in rubber bridge.
          if ['over', 'under', 'slambonus', 'insultbonus'].include?(key)
            above += value
          elsif key == 'odd'
            below += value
          end
        end
      end
      return [above, below]
    end
  end



  # A rubber set, in which pairs compete to make two consecutive games.
  # A game is made by accumulation of 100+ points from below-the-line scores
  # without interruption from an opponent's game.
  class Rubber < Array
    attr_accessor :games, :winner

    # Returns a list of completed (ie. won) 'games' in this rubber, in the
    # order of their completion.
        
    # A game is represented as a list of consecutive results from this rubber,
    # coupled with the identifier of the scoring pair.
    def _get_games
      games = []

      thisgame = []
      belowNS, belowEW = 0, 0  # Cumulative totals for results in this game.

      self.each do |result|
        thisgame << result
        if [Direction.north, Direction.south].include?(result.contract.declarer)
          belowNS += result.score[1]
          if belowNS >= 100
            games << [thisgame, [Direction.north, Direction.south]]
          else
            belowEW += result.score[1]
            if belowEW >= 100
              games << [thisgame, [Direction.east, Direction.west]]
            end
          end
          # If either total for this game exceeds 100, proceed to next game.
          if belowNS >= 100 or belowEW >= 100  
            thisgame = []
            belowNS, belowEW = 0, 0  # Reset accumulators.
          end
        end
      end
      return games
    end
    
    # The rubber is won by the pair which have completed two games.
    def _get_winner
      pairs = self.games.map { |game, pair| pair }
      [[Direction.north, Direction.south], [Direction.east, Direction.west]].each do |pair|
        pair if pairs.count(pair) >= 2
      end
    end
  end
end
          
