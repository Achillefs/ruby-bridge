require 'spec_helper'

describe Result do
  let(:calls) {[
    Pass.new(), Pass.new(), Bid.new(Level.one, Strain.club), Double.new(),
    Redouble.new(), Pass.new(), Pass.new(), Bid.new(Level.one, Strain.no_trump),
    Pass.new(), Bid.new(Level.two, Strain.heart), Pass.new(), Pass.new(),
    Pass.new()
  ]}
  
  let(:game) {
    # set up game objects
    game = Game.new
    
    board = Board.new(
      :deal => Deal.new, 
      :dealer => Direction.north, 
      :vulnerability => Vulnerability.all
    )
    
    players = []
    Direction.each do |position|
      players[position] = game.add_player(position)
    end
    
    # perform contract
    game.start!(board)
    turn = board.dealer  # Avoid calling getTurn.
    calls.each do |c|
      players[turn].make_call(c) # Each player passes.
      turn = Direction[(turn+1) % Direction.size]
    end
    
    while not game.play.complete?
      expect(game.state).to eq(:playing)
      turn = game.get_turn
      
      # Find a valid card.
      board.deal[turn].each do |card|
        if game.play.valid_play?(card, turn, board.deal[turn])
          if turn == game.play.dummy
            expect(players[game.play.declarer].play_card(card)).to eq(true)
          else
            expect(players[turn].play_card(card)).to eq(true)
          end
          break
        end
      end
    end
    # Game complete, return it
    game
  }
  subject { game.results.first }
  xit { expect(subject.is_major).to eq(true) }
  
  describe 'score tests' do
    let(:calls) {[Bid.new(Level.one, Strain.no_trump), Pass.new, Pass.new, Pass.new]}
    
    it 'should score a 1NT+3 game correctly' do
      r = DuplicateResult.new(game.board, game.contract, 10)
      expect(r.score).to eq(180)
    end
  end
end