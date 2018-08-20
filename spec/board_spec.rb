require 'spec_helper'

describe Board do
  subject { Board.first }
  
  it { expect(subject.number).to eq(1) }
  it { expect(subject.vulnerability).to eq(0) }
  it { expect(subject.dealer).to eq(0) }
  it { expect(subject.deal.hands.size).to eq(4) }
  it { subject.deal.hands.each { |h| expect(h.size).to eq(13) } }
  
  describe '#next' do
    let(:next_board) { subject.next }
    
    it { expect(next_board.number).to eq(2) }
    it { expect(next_board.vulnerability).to eq(1) }
    it { expect(next_board.dealer).to eq(1) }
  end
end