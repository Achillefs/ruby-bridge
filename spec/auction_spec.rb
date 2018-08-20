require 'spec_helper'

describe Auction do
  include AuctionHelper
  
  let(:dealer) { Direction.north }
  let(:calls) { 
    [Pass.new(), Pass.new(), Bid.new(Level.one, Strain.club), Double.new(),
    Redouble.new(), Pass.new(), Pass.new(), Bid.new(Level.one, Strain.no_trump),
    Pass.new(), Bid.new(Level.three, Strain.no_trump), Pass.new(), Pass.new(),
    Pass.new()]
  }
  
  subject(:instance) { Auction.new(dealer) }
  
  it { expect(subject.contract).to be_a(NilClass) }
  it { expect(subject.get_contract).to be_a(NilClass) }
  it { expect(subject.calls.size).to eq(0) }
  it { expect(subject.dealer).to eq(dealer) }
  
  it 'should pass out on 4 passes only' do
    expect(subject.passed_out?).to eq(false)
    3.times do
      expect(subject.make_call(Pass.new)).to eq(true)
      expect(subject.passed_out?).to eq(false)
    end
    
    expect(subject.make_call(Pass.new)).to eq(true)
    expect(subject.passed_out?).to eq(true)
  end
  
  describe 'when finished' do
    before { calls.each { |call| subject.make_call(call) } }
    
    it { expect(subject.calls).to eq(calls) }
    it { expect(subject.contract).to_not be_a(NilClass) }
    it { expect(subject.contract).to be_a(Contract) }
    it { expect(subject.get_contract).to be_a(Hash) }
    it { expect(subject.get_contract).to eq(subject.contract.to_hash) }
  end
  
  describe 'current call' do
    it { assert_current_calls([nil,nil,nil]) }
    
    it 'should set current bid' do
      assert_current_calls [Bid.new(Level.one, Strain.diamond)]
    end
    
    it 'should set current double' do
      assert_current_calls [ Bid.new(Level.one, Strain.diamond), Double.new ]
    end
    
    it 'should set current redouble' do
      assert_current_calls [ Bid.new(Level.one, Strain.diamond), Double.new, Redouble.new ]
    end
  end
  
  it 'does not allow invalid calls' do
    subject.make_call(Bid.new(Level.two, Strain.club))
    expect { subject.make_call(Bid.new(Level.one, Strain.club)) }.to raise_error(Bridge::InvalidCallError)
    expect { subject.make_call(Bid.new(Level.three, Strain.club)) }.to_not raise_error
    expect { subject.make_call(Bid.new(Level.two, Strain.heart)) }.to raise_error(Bridge::InvalidCallError)
    expect { subject.make_call(Bid.new(Level.three, Strain.heart)) }.to_not raise_error
  end
  
  it 'knows whose turn it is' do
    turn = dealer
    expect(subject.whose_turn).to eq(turn)
    
    calls.each_index do |i|
      subject.make_call(calls[i])
      if i == calls.size - 1
        expect(subject.whose_turn).to eq(nil)
      else
        turn = Direction[(turn + 1) % 4]  # Turn moves clockwise.
        expect(subject.whose_turn).to eq(turn)
      end
    end
  end
  
  it 'only marks an auction as complete if it is' do
    expect(subject.complete?).to eq(false)
    calls.each_index do |i|
      subject.make_call(calls[i])
      if i == calls.size - 1
        expect(subject.complete?).to eq(true)
      else
        expect(subject.complete?).to eq(false)
      end
    end
  end
  
  it 'knows if a call is valid' do
    calls.each_index do |i|
      subject.make_call(calls[i])
      next_call = calls[i+1]
      expect(subject.valid_call?(next_call)).to eq(true) unless next_call.nil?
    end
  end
end
