require 'rubygems'
require 'ostruct'
require 'pathname'
require 'json'
require 'nutrun-string'

root = File.dirname(__FILE__)

%W{ enum }.each { |r| require File.join(root,r) }

module Bridge
  DEBUG = false
  
  module Direction 
    extend Enum
    set_values :north, :east, :south, :west
  end
  
  module Vulnerability
    extend Enum
    set_values :none, :north_south, :east_west, :all
  end
  
  def root
    File.dirname(__FILE__)
  end
  
  def assert_card card
    raise CardError, "Card #{card.inspect} is not valid" unless card.is_a?(Card)
  end
  
  module_function :assert_card
  public :assert_card
end

Dir[File.join(root,'bridge','*.rb')].each { |r| require r }