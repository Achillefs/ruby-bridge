require 'spec_helper'

describe TrickPlay do
  
  subject { TrickPlay.new(Direction.east,Suit.club) }
  let(:board) {
    Board.new(
      :deal => Deal.new, 
      :dealer => Direction.east, 
      :vulnerability => Vulnerability.all
    )
  }
  
  
  it { expect(subject.declarer).to eq(Direction.east) }
  it { expect(subject.lho).to eq(Direction.south) }
  it { expect(subject.rho).to eq(Direction.north) }
  it { expect(subject.dummy).to eq(Direction.west) }
  it { expect(subject.trumps).to eq(Suit.club) }
  it { expect(subject.played.size).to eq(4) }
  it { expect(subject.winners.size).to eq(0) }
  it { expect(subject.complete?).to eq(false) }
  it { expect(subject.whose_turn).to eq(Direction.south) }
  it { expect(subject.get_current_trick.cards.size).to eq(0) }
  
  describe '#play_card' do
    let(:card1) { Card.from_string('JC') }
    let(:card2) { Card.from_string('2C') }
    let(:card3) { Card.from_string('8C') }
    let(:card4) { Card.from_string('5C') }
    let(:card5) { Card.from_string('10H') }
    
    before { subject.play_card(card1,nil) }
    
    it { expect(subject.get_trick_count).to eq([0,0]) }
    it { expect(subject.get_current_trick.cards.compact.size).to eq(1) }
    it { expect(subject.winning_card(subject.get_current_trick)).to eq(false) }
    it { expect(subject.whose_turn).to eq(Direction.west) }
    it { expect(subject.played[Direction.south].size).to eq(1) }
    it { expect(subject.history.size).to eq(1) }
    it { expect(subject.who_played?(card1)).to eq(Direction.south) }
    
    describe '2 times' do
      before { subject.play_card(card2,nil) }
      
      it { expect(subject.get_trick_count).to eq([0,0]) }
      it { expect(subject.get_current_trick.cards.compact.size).to eq(2) }
      it { expect(subject.get_current_trick.cards.size).to eq(4) }
      it { expect(subject.winning_card(subject.get_current_trick)).to eq(false) }
      it { expect(subject.whose_turn).to eq(Direction.north) }
      it { expect(subject.played[Direction.west].size).to eq(1) }
      it { expect(subject.who_played?(card2)).to eq(Direction.west) }
      
      describe '3 times' do
        before { subject.play_card(card3,nil) }
        
        it { expect(subject.get_trick_count).to eq([0,0]) }
        it { expect(subject.get_current_trick.cards.compact.size).to eq(3) }
        it { expect(subject.get_current_trick.cards.size).to eq(4) }
        it { expect(subject.winning_card(subject.get_current_trick)).to eq(false) }
        it { expect(subject.whose_turn).to eq(Direction.east) }
        it { expect(subject.played[Direction.north].size).to eq(1) }
        it { expect(subject.who_played?(card3)).to eq(Direction.north) }
      
        describe '4 times' do
          before { subject.play_card(card4,nil) }
          
          it { expect(subject.get_trick_count).to eq([0,1]) } # south won
          it { expect(subject.get_current_trick.cards.compact.size).to eq(4) }
          it { expect(subject.get_current_trick.cards.size).to eq(4) }
          it { expect(subject.winning_card(subject.get_current_trick)).to eq(card1) }
          it { expect(subject.whose_turn).to eq(Direction.south) }
          it { expect(subject.played[Direction.east].size).to eq(1) }
          it { expect(subject.who_played?(card4)).to eq(Direction.east) }
          
          describe '5 times' do
            before { subject.play_card(card5,nil) }
            it { expect(subject.get_trick_count).to eq([0,1]) } # south won
            it { expect(subject.get_current_trick.cards.compact.size).to eq(1) }
            it { expect(subject.winning_card(subject.get_current_trick)).to eq(false) }
            it { expect(subject.whose_turn).to eq(Direction.west) }
            it { expect(subject.played[Direction.south].size).to eq(2) }
            it { expect(subject.who_played?(card5)).to eq(Direction.south) }
          end
        end
      end
    end
  end
end