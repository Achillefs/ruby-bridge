module AuctionHelper
  # expects an array of calls
  def assert_current_calls(calls)
    calls.map { |c| subject.make_call(c) unless c.nil? }
    expect(subject.current_bid).to eq(calls[0])
    expect(subject.current_double).to eq(calls[1])
    expect(subject.current_redouble).to eq(calls[2])
  end
end