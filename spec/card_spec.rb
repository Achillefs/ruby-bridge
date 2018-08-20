require 'spec_helper'

describe Card do

  let(:card){ Card.new('2', 'C') }

  it "sets rank on initialize" do
    expect(card.rank).to eq('2')
  end

  it "sets suit on initialize" do
    expect(card.suit).to eq('C')
  end

  it "returns a string with rank and suit" do
    expect(card.to_s).to eq('2C')
  end
  
  it { expect(card.suit_i).to eq(Suit.club) }
  
  describe "honour" do
    it "has an honour of 4 when rank is A" do
      expect(Card.new('A','H').honour).to eq(4)
    end

    it "has an honour of 3 when rank is K" do
      expect(Card.new('K','H').honour).to eq(3)
    end

    it "has an honour of 2 when rank is Q" do
      expect(Card.new('Q','H').honour).to eq(2)
    end

    it "has an honour of 1 when rank is J" do
      expect(Card.new('J','H').honour).to eq(1)
    end

    it "has an honour of 0 when rank is a number" do
      expect(Card.new('5','H').honour).to eq(0)
    end
  end
  
  describe "#from_string" do
    it { expect { Card.from_string('2') }.to   raise_error(CardError) }
    it { expect { Card.from_string('WAT') }.to raise_error(CardError) }
    it { expect { Card.from_string('GT') }.to  raise_error(CardError) }
    it { expect { Card.from_string('GC') }.to  raise_error(CardError) }
    it { expect { Card.from_string('2F') }.to  raise_error(CardError) }
    it { expect(Card.from_string('10C')).to eq(Card.new('10','C')) }
    it { expect(Card.from_string('2C')).to eq(card) }
    it { expect(Card.from_string('2C').rank).to eq('2') }
    it { expect(Card.from_string('2C').suit).to eq('C') }
  end
  
  describe "<=>" do
    let(:cards) do
      cards = []
      for rank in Card::RANKS do
        for suit in Card::SUITS do
          cards << Card.new(rank, suit)
        end
      end

      cards
    end
    
    let(:other_cards) do
      cards = []
      for rank in Card::RANKS do
        for suit in Card::SUITS do
          cards << Card.new(rank, suit)
        end
      end

      cards
    end

    it "compares to other cards" do
      expect(Card.new('2','C') < Card.new('2','D')).to eq(true)
      expect(Card.new('2','C') > Card.new('2','D')).to eq(false)
      expect(Card.new('2','C') == Card.new('2','D')).to eq(false)
    end
    
    it "compares to other cards of same suit" do
      expect(Card.new('2','C') < Card.new('J','C')).to eq(true)
      expect(Card.new('2','C') > Card.new('J','C')).to eq(false)
      expect(Card.new('2','C') == Card.new('J','C')).to eq(false)
    end

    it "compares as equal to same card" do
      cards.each { |c| expect(c).to eq(c) } # same card
      cards.each_index { |i| expect(cards[i]).to eq(other_cards[i]) } # same card, different object
    end
  end
end
