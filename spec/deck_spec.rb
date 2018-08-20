require 'spec_helper'

describe Deck do

  subject { Deck.new }

  it { expect(subject.size).to eq(52) }
  
  it "should be shuffleable" do
    old_deck = subject.clone
    subject.shuffle!
    expect(subject).to_not eq(old_deck)
  end
end
