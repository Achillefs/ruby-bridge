module Bridge
  class Player
    def initialize(game)
      @game = game  # Access to game is private to this object.
    end

    def get_hand
      position = game.players[self]
      return game.get_hand(position)
    end
    alias :hand :get_hand

    def make_call(call)
      begin
        return game.make_call(call, player = self)
      rescue Exception => e
        if Bridge::DEBUG
          puts e.backtrace.first(8).join("\n").red
          puts "\n"
        end
        raise GameError, e.message
      end
    end
    
    def play_card(card)
      begin
        return self.game.play_card(card, self)
      rescue Exception => e
        if Bridge::DEBUG
          puts e.backtrace.first(8).join("\n").red
          puts "\n"
        end
        raise GameError, e.message
      end
    end

    def start_next_game
      raise GameError, "Not ready to start game" unless game.next_game_ready?
      game.start!
    end
    
  protected
    def game
      @game
    end
  end
end
