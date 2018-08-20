require 'spec_helper'

describe Enum do

  subject { TestEnum }

  it { expect(subject.size).to eq(4) }
  it { expect(subject.first).to eq(0) }
  it { expect(subject.next(0)).to eq(1) }
  it { expect(subject[0]).to eq(0) }
  it { expect(subject.oh).to eq(0) }
  it { expect(subject.name(0)).to eq('oh') }
  it { expect(subject.each).to be_a(Enumerator) }
end
