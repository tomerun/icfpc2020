require "./defs.cr"

alias List = BigInt | Array(List)

def mod(i : BigInt, io)
  if i < 0
    io << "10"
    i = i.abs
  else
    io << "01"
  end
  base2 = i.to_s(2)
  len = i == 0 ? 0 : (base2.size + 3) // 4
  io << "1" * len << "0"
  if len > 0
    io << "0" * (len * 4 - base2.size) << base2
  end
end

def mod(l : List, io)
  case l
  when BigInt
    mod(l, io)
  else
    if l.size == 0
      io << "00"
    elsif l.size == 1
      io << "11" << mod(l[0]) << "00"
    else
      (l.size - 1).times do |i|
        io << "11" << mod(l[i])
      end
      io << mod(l[-1])
    end
  end
end

def mod(l : List) : String
  return String.build do |io|
    mod(l, io)
  end
end

def mod(n : Node, io)
  case n
  when Ap
    assert(n.x0.as(Ap).x0.is_a?(Cons))
    car = n.x0.as(Ap).x1
    cdr = n.x1
    io << "11"
    mod(car, io)
    mod(cdr, io)
  when IntAtom
    mod(n.v, io)
  when NilAtom
    io << "00"
  else
    assert(false)
  end
end

def mod(n : Node) : String
  return String.build do |io|
    mod(n, io)
  end
end

def demod(str : String, pos : Int32) : Tuple(Node, Int32)
  if str[pos] == '1' && str[pos + 1] == '1'
    car, pos = demod(str, pos + 2)
    cdr, pos = demod(str, pos)
    return {Ap.new(Ap.new(Cons.new, car), cdr), pos}
  elsif str[pos] == '0' && str[pos + 1] == '0'
    return {NilAtom.new, pos + 2}
  else
    sign = str[pos] == '0' ? 1 : -1
    pos += 2
    len = 0
    while str[pos] == '1'
      len += 1
      pos += 1
    end
    pos += 1
    if len == 0
      return {IntAtom.new(BigInt.new(0)), pos}
    else
      last = pos + 4 * len
      return {IntAtom.new(BigInt.new(str[pos...last], base: 2) * sign), last}
    end
  end
end

def demod(str : String) : Node
  return demod(str, 0)[0]
end

def from_list(l : Array(List)) : Node
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

def get_list(str : String) : Array(List)
  return get_list(demod(str))
end

def get_list(node : Node) : Array(List)
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
