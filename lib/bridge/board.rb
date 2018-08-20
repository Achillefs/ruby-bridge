module Bridge
  # An encapsulation of board information.
  # @keyword deal: the cards in each hand.
  # @type deal: Deal
  # @keyword dealer: the position of the dealer.
  # @type dealer: Direction
  # @keyword event: the name of the event where the board was played.
  # @type event: str
  # @keyword num: the board number.
  # @type num: int
  # @keyword players: a mapping from positions to player names.
  # @type players: dict
  # @keyword site: the location (of the event) where the board was played.
  # @type site: str
  # @keyword time: the date/time when the board was generated.
  # @type time: time.struct_time
  # @keyword vuln: the board vulnerability.
  # @type vuln: Vulnerable
  class Board
    attr_accessor :vulnerability, :players, :dealer, :deal, :number
    attr_accessor :created_at
    
    def initialize opts = {}
      opts = {
        :deal => Deal.new,
        :number => 1,
        :dealer => Direction.north,
        :vulnerability => Vulnerability.none
      }.merge(opts)
      
      opts.map { |k,v| self.send(:"#{k}=",v) if self.respond_to?(k) }
      self.created_at = Time.now
    end
    
    # Builds and returns a successor board to this board.
    # The dealer and vulnerability of the successor board are determined from
    # the board number, according to the rotation scheme for duplicate bridge.
    # @param deal: if provided, the deal to be wrapped by next board.
    # Otherwise, a randomly-generated deal is wrapped.
    def self.first deal = nil
      self.new(
        :deal => deal || Deal.new,
        :number => 1,
        :dealer => Direction.north,
        :vulnerability => Vulnerability.none
      )
    end

    # Builds and returns a successor board to this board.
    # The dealer and vulnerability of the successor board are determined from
    # the board number, according to the rotation scheme for duplicate bridge.
    # @param deal: if provided, the deal to be wrapped by next board.
    # Otherwise, a randomly-generated deal is wrapped.
    def next deal = nil
      board = Board.new
      board.deal = deal || Deal.new
      board.number = self.number + 1
      board.created_at = Time.now

      # Dealer rotates clockwise.
      board.dealer = Direction.next(self.dealer)

      # Map from duplicate board index range 1..16 to vulnerability.
      # See http://www.d21acbl.com/References/Laws/node5.html#law2
      i = (board.number - 1) % 16
      board.vulnerability = Vulnerability[(i%4 + i/4)%4]

      return board
    end
    
    def to_json(opts = {})
      h = {}
      [:vulnerability, :players, :dealer, :deal, :number, :created_at].each do |a|
        h[a] = send(a)
      end
      h.to_json
    end
    
    def copy
      self.clone
    end
  end
end