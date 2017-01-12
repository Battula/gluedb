# A window iterator for arrays.
class ArrayWindow
  include Enumerable

  def initialize(source_array)
    @array = source_array 
  end

  def each
    @array.each_index do |i|
      head = @array.first(i)
      element = @array[i]
      tail = @array[(i+1)..-1]
      yield [element, head, tail]
    end
  end

  def chunk_adjacent
    return([@array]) if @array.length < 2
    result_array = [[@array.first]]
    @array.each_cons(2) do |items|
      a, b = items
      break_it = yield(a, b)
      *init, last_item = result_array
      if break_it
        result_array = result_array + [[b]]
      else
        result_array = init + [(last_item + [b])]
      end
    end
    result_array
  end
end
