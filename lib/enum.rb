# set values on each child like so:
# set_values :north, :east, :south, :west
module Enum
  def set_values *args
    self.define_singleton_method(:values) { args }
    args.each_index do |i|
      self.define_singleton_method(args[i]) { i }
    end
  end
  
  def next index
    next_index = index + 1
    send(values[next_index].nil? ? values.first : values[next_index])
  end
  
  def [] index
    self.send(values[index])
  end
  
  def name index
    values[index].to_s
  end
  
  def all
    values
  end
  
  def method_missing m, *args, &block
    index_array = (0..(values.size-1)).to_a
    index_array.respond_to?(m) ? index_array.send(m,*args,&block) : super
  end
end