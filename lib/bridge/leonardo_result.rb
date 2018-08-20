require Pathname.new(__FILE__).dirname.join('result')

module Bridge
  # custom leonardo bridge result logic
  class LeonardoResult < DuplicateResult
  end
end