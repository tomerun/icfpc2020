require "./defs.cr"
require "./modem.cr"
require "./parser.cr"

alias List = BigInt | Array(List)

class Reducer
  def initialize
    @context = ReduceContext.new
  end

  def execute(io)
    protocol = nil : Node?
    io.each_line do |line|
      parser = Parser.new(line)
      if line[0] == ':'
        assignment = parser.parse_assign.not_nil!
        @context.vars[assignment.num] = assignment.node
      else
        proto_name = parser.next_token
        puts "protocol name: #{proto_name}"
        parser.next_token # skip " = "
        protocol = parser.parse_expr
      end
    end
    # state = NilAtom.new
    # # l0 = Ap.new(Ap.new(Cons.new, IntAtom.new(0)), NilAtom.new)
    # # l1 = Ap.new(Ap.new(Cons.new, IntAtom.new(0)), l0)
    # input = [] of List
    # input << BigInt.new(0) << BigInt.new(0)
    # data = from_list(input)
    # while true
    #   reduced = execute_single(protocol.not_nil!, state, data)
    #   result = get_list(reduced)
    #   flag = result[0].as(BigInt)
    #   puts "flag:#{flag}"
    #   state_list = result[1].as(Array(List))
    #   puts "state:#{state}"
    #   state = from_list(state_list)
    #   data = result[2]
    #   puts "data:#{data}"
    #   break if flag == 0
    #   received = read_line
    #   data = demod(received)
    #   puts "received:#{received}"
    #   puts "new_data:#{data}"
    # end

    pos = [[0, 0], [2, 3], [1, 2], [3, 2], [4, 0]]
    state = NilAtom.new
    pos.each do |p|
      input = [] of List
      input << BigInt.new(p[0]) << BigInt.new(p[1])
      data = from_list(input)
      reduced = execute_single(protocol.not_nil!, state, data)
      result = get_list(reduced)
      puts "result:#{result}"
      flag = result[0].as(BigInt)
      puts "flag:#{flag}"
      state_list = result[1].as(Array(List))
      puts "state:#{state}"
      state = from_list(state_list)
      data = result[2]
      puts "data:#{data}"
      # received = read_line
      # data = demod(received)
      # puts "received:#{received}"
      # puts "new_data:#{data}"
    end
  end

  def execute_single(protocol, state, data)
    protocol.clear
    top1 = Ap.new(protocol, state)
    top2 = Ap.new(top1, data)
    @context.root = top2
    puts String.build { |io| top2.to_s(io, 0) }
    res = top2.reduce(@context).not_nil!
    puts String.build { |io| res.to_s(io, 0) }
    return res
  end
end

def from_list(l : Array(List))
  prev = NilAtom.new
  l.reverse.each do |e|
    if e.is_a?(BigInt)
      car = IntAtom.new(e)
    else
      car = from_list(e)
    end
    prev = Ap.new(Ap.new(Cons.new, car), prev)
  end
  return prev
end

def get_list(node : Node)
  l = [] of List
  while !node.is_a?(NilAtom)
    assert(node.is_a?(Ap))
    assert(node.as(Ap).x0.as(Ap).x0.is_a?(Cons))
    car = node.as(Ap).x0.as(Ap).x1
    case car
    when IntAtom
      l << BigInt.new(car.as(IntAtom).v)
    when NilAtom
      l << [] of List
    when Ap
      l << get_list(car)
    else
      assert(false, car.to_s)
    end
    node = node.as(Ap).x1
  end
  return l
end

reducer = Reducer.new
reducer.execute(ARGF)
