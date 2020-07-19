require "./defs.cr"
require "./modem.cr"
require "./parser.cr"

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
    state = NilAtom.new
    input = [] of List
    input << BigInt.new(0) << BigInt.new(0)
    data = from_list(input)
    data = Ap.new(Ap.new(Cons.new, IntAtom.new(0)), IntAtom.new(0))
    while true
      while true
        reduced = execute_single(protocol.not_nil!, state, data)
        result = get_list(reduced)
        puts "result:#{result}"
        flag = result[0].as(BigInt)
        puts "flag:#{flag}"
        state_list = result[1].as(Array(List))
        state = from_list(state_list)
        # puts "state:#{state}"
        data = result[2].as(Array(List))
        puts "data:#{data}"
        draw(data)
        break if flag == 0
        puts "send #{mod(data)}"
        received = read_line
        data = demod(received)
        puts "received:#{received}"
        puts "new_data:#{data}"
      end
      puts "input next pos"
      y, x = read_line.split.map(&.to_i)
      puts "click (#{y},#{x})"
      data = Ap.new(Ap.new(Cons.new, IntAtom.new(x)), IntAtom.new(y))
    end
  end

  def execute_single(protocol, state, data)
    top1 = Ap.new(protocol.clone, state)
    top2 = Ap.new(top1, data)
    @context.root = top2
    # puts String.build { |io| top2.to_s(io, 0) }
    res = top2.reduce(@context).not_nil!
    # puts String.build { |io| res.to_s(io, 0) }
    return res
  end
end

def draw(data : Array(List))
  pos = Array(Tuple(Int32, Int32)).new
  data.each do |e|
    e.as(Array(List)).each do |p|
      x = p.as(Array(List))[0].as(BigInt).to_i
      y = p.as(Array(List))[1].as(BigInt).to_i
      pos << {y, x}
    end
  end
  minx = 0
  maxx = 0
  miny = 0
  maxy = 0
  pos.each do |p|
    minx = {minx, p[1]}.min
    maxx = {maxx, p[1]}.max
    miny = {miny, p[0]}.min
    maxy = {maxy, p[0]}.max
  end
  puts "(#{minx},#{miny})-(#{maxx},#{maxy})"
  screen = Array.new(maxy - miny + 1) { Array.new(maxx - minx + 1, false) }
  pos.each do |p|
    screen[p[0] - miny][p[1] - minx] = true
  end
  top = "   " + minx.to_s
  top += " " * (maxx - minx - top.size - 1 + 3)
  top += maxx.to_s
  puts
  puts top
  miny.upto(maxy) do |y|
    printf("% 2d ", y)
    screen[y - miny].each do |pixel|
      print(pixel ? "#" : " ")
    end
    puts
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
  while true
    if node.is_a?(NilAtom)
      break
    end
    if node.is_a?(IntAtom)
      l << BigInt.new(node.v)
      break
    end
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
