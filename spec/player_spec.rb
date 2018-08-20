require 'spec_helper'

describe Player do
  let(:game) { Game.new }
  
  context 'with one player' do
    subject { game.add_player(Direction.north) }
  
    it 'should not have a hand while in auction' do
      expect { subject.hand }.to raise_error(GameError, 'Hand unknown')
    end
  
    it 'should not be able to start next game' do
      expect { subject.start_next_game }.to raise_error(GameError, 'Not ready to start game')
    end
  
    it ").to be able to start a game if available" do
      allow(subject.send(:game)).to receive(:next_game_ready?).and_return(true)
      expect(subject.start_next_game).to eq(true)
    end
  end
end