require 'spec_helper'

describe Trick do
  subject { Trick.new }
  
  it { expect(subject.done?).to eq(false) }
  it { expect(subject.leader).to eq(nil) }
  it { expect(subject.cards).to eq([]) }
  
  describe 'with 4 cards' do
    before { Deck.new.first(4).each { |c| subject << c } }
    
    it { expect(subject.done?).to eq(true) }
  end
end