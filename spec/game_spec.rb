# ported from https://svn.code.sf.net/p/pybridge/code/trunk/pybridge/tests/bridge/test_game.py
require 'spec_helper'

describe Game do
  subject { Game.new }
  let(:board) {
    Board.new(
      :deal => Deal.new, 
      :dealer => Direction.north, 
      :vulnerability => Vulnerability.all
    )
  }
  
  it { expect(subject.in_progress?).to eq(false) }
  it { expect(subject.state).to eq(:new) }
  it { expect { subject.get_turn }.to raise_error(GameError) }
  
  describe 'in #rubber_mode' do
    subject { Game.new(:rubber_mode => true) }
    
    it 'sets rubber mode' do
      expect(subject.rubbers).to eq([])
    end
    
    it ").to set vulnerability" do
      subject.start!(board)
      subject.board.vulnerability = Vulnerability.none
    end
  end
  
  it 'should start with the first board by default' do
    subject.start!
    expect(subject.board.number).to eq(1)
  end
  
  it 'should increment boards' do
    g = Game.new(:board => Board.first)
    g.start!
    expect(g.board.number).to eq(2)
  end
  
  describe '#start!' do
    before { subject.start! }
    
    it { expect(subject.state).to eq(:auction) }
    it { expect(subject.in_progress?).to eq(true) }
    it { expect(subject.get_turn).to eq(subject.board.dealer) }
  end
  
  describe '#start with board' do
    before { subject.start!(board) }
    
    it { expect(subject.board).to eq(board) }
    it { expect(subject.get_turn).to eq(board.dealer) }
  end
  
  describe 'player methods' do
    before {
      players = []
      Direction.each do |position|
        players[position] = subject.add_player(position)
      end
    }
    it { expect(subject.players.size).to eq(4) }
    it { expect { subject.add_player(Direction.north) }.to raise_error(GameError) }
    
    it 'should be able to remove all players' do
      Direction.each do |position|
        expect { subject.remove_player(position) }.to_not raise_error
      end
      
      expect { subject.remove_player(Direction.north) }.to raise_error(GameError)
    end
  end
  
  describe 'running game' do
    let(:players) {
      players = []
      Direction.each do |position|
        players[position] = subject.add_player(position)
      end
      players
    }
    
    describe '#get_state' do
      let(:calls) { 
        [Pass.new(), Pass.new(), Bid.new(Level.one, Strain.club), Double.new(),
        Redouble.new(), Pass.new(), Pass.new(), Bid.new(Level.one, Strain.no_trump),
        Pass.new(), Bid.new(Level.two, Strain.heart), Pass.new(), Pass.new(),
        Pass.new()]
      }
      
      context 'in auction' do
        before { 
          @players = []
          Direction.each { |p| @players[p] = subject.add_player(p) }
          subject.start!(board)
        }
        
        it 'to return all available calls at start' do
          expect(subject.get_state[:calls].size).to eq(38)
          expect(subject.get_state[:available_calls].size).to eq(36)
        end
        
        it 'should return available calls' do
          @players[subject.get_turn].make_call(Call.from_string('b two heart'))
          expect(subject.get_state[:calls].size).to eq(38)
          expect(subject.get_state[:available_calls].size).to eq(29)
        end
      end
      
      context "passed out" do
        before {
          subject.start!(board)
          turn = board.dealer  # Avoid calling getTurn.™
          Direction.each do |i| # Iterate for each player.
            players[i].make_call(Pass.new) # Each player passes.
            turn = Direction[(turn+1) % Direction.size]
          end
        }
      
        it 'should return game state' do
          state = subject.get_state
          expect(state).to be_a(Hash)
          expect(state[:state]).to eq(:finished)
          expect(state[:available_calls]).to eq([])
          expect(state[:auction].size).to eq(4)
          expect(state[:turn]).to eq(nil)
          expect(state[:play]).to eq(nil)
        end
      end
      
      context '#undo' do
        before { subject.start!(board) }
        
        it 'should work during auction' do
          turn = board.dealer
          calls.first(3).each do |c|
            players[turn].make_call(c) # Each player passes.
            turn = Direction[(turn+1) % Direction.size]
          end
          call_size = subject.auction.calls.size
          
          expect(subject.undo!).to eq(true)
          expect(subject.auction.calls.size).to eq(call_size-1)
          expect(subject.get_turn).to eq(turn-1)
        end
        
        it 'should not work with a completed auction and no cards' do
          turn = board.dealer
          calls.each do |c|
            players[turn].make_call(c) # Each player passes.
            turn = Direction[(turn+1) % Direction.size]
          end
          call_size = subject.auction.calls.size
          turn = subject.get_turn
          expect(subject.undo!).to eq(false)
          expect(subject.auction.calls.size).to eq(call_size)
          expect(subject.get_turn).to eq(turn)
        end
        
        context 'with complete auction' do
          before {
            turn = board.dealer
            calls.each do |c|
              players[turn].make_call(c) # Each player passes.
              turn = Direction[(turn+1) % Direction.size]
            end
          }
          
          it 'should work while in play' do
            5.times do # play 3 cards
              turn = subject.get_turn
              # Find a valid card.
              board.deal[turn].each do |card|
                if subject.play.valid_play?(card, turn, board.deal[turn])
                  if turn == subject.play.dummy
                    self.players[subject.play.declarer].play_card(card)
                  else
                    self.players[turn].play_card(card)
                  end
                  break
                end
              end
            end
            
            turn = subject.get_turn
            
            # We can undo all the way to the bank baby
            expect(subject.undo!).to eq(true)
            expect(subject.play.get_current_trick.cards.compact.size).to eq(4)
            expect(subject.get_turn).to eq(turn-1 % 4)
            
            p1 = subject.play.whose_turn
            expect(subject.undo!).to eq(true)
            p2 = subject.play.whose_turn
            
            expect(p1).to_not eq(p2)
            count = subject.board.deal.hands[p2].size
            
            expect(subject.play.get_current_trick.cards.compact.size).to eq(3)
            expect(subject.board.deal.hands[p2].size).to eq(count+1)
            
            expect(subject.undo!).to eq(true)
            expect(subject.play.get_current_trick.cards.compact.size).to eq(2)
            
            expect(subject.undo!).to eq(true)
            expect(subject.play.get_current_trick.cards.compact.size).to eq(1)
            
            expect(subject.undo!).to eq(true)
            expect(subject.play.get_current_trick.cards.compact.size).to eq(0)
            
            expect(subject.undo!).to eq(false)
            expect(subject.play.get_current_trick.cards.compact.size).to eq(0)
          end
        end
      end
      
      context "auctioned" do
        before {
          subject.start!(board)
          turn = board.dealer  # Avoid calling getTurn.
          calls.each do |c|
            players[turn].make_call(c) # Each player passes.
            turn = Direction[(turn+1) % Direction.size]
          end
        }
      
        it 'should return game state' do
          state = subject.get_state
          expect(state).to be_a(Hash)
          expect(state[:auction].size).to eq(13)
          expect(state[:available_calls]).to eq([])
          expect(state[:play]).to be_a(Hash)
          expect(state[:state]).to eq(:playing)
          expect(state[:turn]).to eq(2) # this is now game turn
          expect(Strain.name(state[:play][:trumps])).to eq('heart')
          expect(state[:contract][:bid].to_s).to eq('two heart')
          expect(Direction.name(state[:play][:declarer])).to eq('east')
          expect(Direction.name(state[:play][:dummy])).to eq('west')
          expect(state[:play][:declarer_trick_count]).to eq(0)
          expect(state[:play][:defender_trick_count]).to eq(0)
          expect(state[:play][:tricks]).to be_a(Array)
          expect(state[:play][:tricks].size).to eq(0)
        end
        
        it 'should return well-formed json state' do
          state = JSON.parse(subject.get_state.to_json)
          expect(state['state']).to eq('playing')
          expect(state['auction'].size).to eq(13)
          expect(state['auction'].first).to eq('pass')
        end
        
        context 'in play' do
          before {
            @turn  = subject.get_turn
            player = players[@turn]
            @card = player.get_hand.sample
            player.play_card(@card) # play a random card
          }
          
          it 'should include public cards' do
            state = subject.get_state
            # go to json and test that for sanity
            state = JSON.parse(state.to_json)
            dummy = state['play']['dummy']
            expect(dummy).to eq(3)
            expect(state['play']['played'][@turn.to_s].first).to eq(@card.to_s)
            expect(state['board']['deal'][dummy.to_s]).to eq(subject.get_hand(dummy).map { |c| c.to_s })
          end
          
          it 'can perform a claim issued by a defender' do
            subject.claim(Direction.north, 9)
            expect(subject.results.size).to eq(1)
            expect(subject.state).to eq(:finished)
            result = subject.results.first
            expect(result.claimed_by).to eq(Direction.north)
            expect(result.claimed).to eq(9)
            expect(result.tricks_made).to eq(4)
            expect(result.score).to eq(-400)
          end
          
          it 'can perform a zero claim issued by a defender' do
            subject.claim(Direction.north, 0)
            expect(subject.results.size).to eq(1)
            expect(subject.state).to eq(:finished)
            result = subject.results.first
            expect(result.claimed_by).to eq(Direction.north)
            expect(result.claimed).to eq(0)
            expect(result.tricks_made).to eq(13)
            expect(result.score).to eq(260)
          end
          
          it 'can perform a claim issued by a declarer' do
            subject.claim(Direction.east, 9)
            expect(subject.results.size).to eq(1)
            expect(subject.state).to eq(:finished)
            result = subject.results.first
            expect(result.claimed_by).to eq(Direction.east)
            expect(result.claimed).to eq(9)
            expect(result.tricks_made).to eq(9)
            expect(result.score).to eq(140)
          end
          
          it 'can perform a zero claim issued by a declarer' do
            subject.claim(Direction.east, 0)
            expect(subject.results.size).to eq(1)
            expect(subject.state).to eq(:finished)
            result = subject.results.first
            expect(result.claimed_by).to eq(Direction.east)
            expect(result.claimed).to eq(0)
            expect(result.tricks_made).to eq(0)
            expect(result.score).to eq(-800)
          end
        end
      end
    end  
    
    # All players pass, game ).to finish without reaching play
    it 'should finish without reaching play if passed out' do
      subject.start!(board)
      turn = board.dealer  # Avoid calling getTurn.
      Direction.each do |i| # Iterate for each player.
        players[i].make_call(Pass.new) # Each player passes.
        turn = Direction[(turn+1) % Direction.size]
      end
      expect(turn).to eq(board.dealer) # Sanity check.

      # Bidding is passed out - game is over.
      expect(subject.in_progress?).to eq(false)
      expect(subject.state).to eq(:finished)
      expect { players[turn].make_call(Bid.new(Level.one, Strain.club)) }.to raise_error(Bridge::GameError)
      expect { players[turn].play_card(board.deal.hands[turn].first) }.to raise_error(Bridge::GameError)
    end
    
    # Play through a sample game.
    # This does not attempt to test the integrity of Bidding and Play.
    it 'should play from start to finish' do
      calls = Level.map do |l| # all available action bids
        Strain.map { |s| Bid.new(l,s) }
      end
      
      calls << [Pass.new, Pass.new, Pass.new] # ...plus 3 passes
      
      subject.start!(board)
      
      calls.flatten.each do |call| # make em all
        turn = subject.get_turn
        players[turn].make_call(call)
      end
      
      expect(subject.state).to eq(:playing)
      expect(subject.auction.complete?).to eq(true)
      expect(subject.play).to_not eq(nil)
      
      while not subject.play.complete?
        expect(subject.state).to eq(:playing)
        turn = subject.get_turn
        # Find a valid card.
        board.deal[turn].each do |card|
          if subject.play.valid_play?(card, turn, board.deal[turn])
            if turn == subject.play.dummy
              expect(self.players[subject.play.declarer].play_card(card)).to eq(true)
            else
              expect(self.players[turn].play_card(card)).to eq(true)
            end
            break
          end
        end
      end
      expect(subject.state).to eq(:finished)
      expect(subject.in_progress?).to eq(false) # Game complete.
    end
  end
end