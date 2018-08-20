require 'spec_helper'

describe Hand do
  subject { 
    hand = Hand.new
    hand.cards = Deck.new.first(12)
    hand
  }
  
  it { expect(subject.size).to eq(12) }
  
  describe '#sort!' do
    before { 
      subject.sort!
      subject.sort! unless subject.cards.map {|c| c.suit}.uniq.size == 4
    }
    
    it { expect(subject.cards.first.suit).to eq('C') }
    it { expect(subject.cards.last.suit).to eq('S') }
  end
end