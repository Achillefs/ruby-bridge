require 'spec_helper'

describe Direction do
  it { expect(Direction.north).to eq(0) }
  it { expect(Direction.east).to  eq(1) }
  it { expect(Direction.south).to eq(2) }
  it { expect(Direction.west).to  eq(3) }
  
  it { expect(Direction.next(Direction.north)).to eq(Direction.east) }
  it { expect(Direction.next(Direction.east)).to  eq(Direction.south) }
  it { expect(Direction.next(Direction.south)).to eq(Direction.west) }
  it { expect(Direction.next(Direction.west)).to  eq(Direction.north) }
end

describe Vulnerability do
  it { expect(Vulnerability.none).to eq(0) }
  it { expect(Vulnerability.north_south).to eq(1) }
  it { expect(Vulnerability.east_west).to eq(2) }
  it { expect(Vulnerability.all).to eq(3) }
  
  it { expect(Vulnerability.next(Vulnerability.none)).to eq(Vulnerability.north_south) }
  it { expect(Vulnerability.next(Vulnerability.north_south)).to eq(Vulnerability.east_west) }
  it { expect(Vulnerability.next(Vulnerability.east_west)).to eq(Vulnerability.all) }
  it { expect(Vulnerability.next(Vulnerability.all)).to eq(Vulnerability.none) }
end