require 'spec_helper'

describe Call do
  it 'can create a pass from a string' do
    expect(Call.from_string('pass')).to be_a(Pass)
    expect(Call.from_string('p')).to be_a(Pass)
    expect(Call.from_string('Pass')).to be_a(Pass)
    expect(Call.from_string('P')).to be_a(Pass)
  end
  
  it 'can create a double from a string' do
    expect(Call.from_string('double')).to be_a(Double)
    expect(Call.from_string('d')).to be_a(Double)
  end
  
  it 'can create a redouble from a string' do
    expect(Call.from_string('redouble')).to be_a(Redouble)
    expect(Call.from_string('r')).to be_a(Redouble)
  end
  
  it 'can create a bid from a string' do
    c = Call.from_string('bid one heart')
    expect(c).to be_a(Bid)
    expect(c.strain).to eq(Strain.heart)
    expect(c.level).to eq(Level.one)
    
    c = Call.from_string('b one heart')
    expect(c.strain).to eq(Strain.heart)
    expect(c.level).to eq(Level.one)
    
    c = Call.from_string('b one no trump')
    expect(c.strain).to eq(Strain.no_trump)
    expect(c.level).to eq(Level.one)
    
    c = Call.from_string('b one no_trump')
    expect(c.strain).to eq(Strain.no_trump)
    expect(c.level).to eq(Level.one)
  end
  
  it 'returns all available calls' do
    expect(Call.all).to be_a(Array)
    expect(Call.all.size).to eq(38)
  end
end