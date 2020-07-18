require "./defs.cr"

def mod(v : NilAtom, io)
  io << "00"
end

def mod(v : IntAtom, io)
  i = v.v
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

def mod(v : Cons, io)
  io << "11"
  case car = v.car
  when Cons
    mod(car, io)
  when IntAtom
    mod(car, io)
  when NilAtom
    mod(car, io)
  else
    raise TypeMismatchError.new(car.to_s)
  end
  case cdr = v.cdr
  when Cons
    mod(cdr, io)
  when IntAtom
    mod(cdr, io)
  when NilAtom
    mod(cdr, io)
  else
    raise TypeMismatchError.new(cdr.to_s)
  end
end

def mod(node : Node) : String
  return String.build do |io|
    case node
    when Cons
      mod(node, io)
    when IntAtom
      mod(node, io)
    when NilAtom
      mod(node, io)
    else
      raise TypeMismatchError.new(node.to_s)
    end
  end
end

def demod(str : String, pos : Int32) : Tuple(Node, Int32)
  if str[pos] == '1' && str[pos + 1] == '1'
    car, pos = demod(str, pos + 2)
    cdr, pos = demod(str, pos)
    return {Cons.new(car, cdr), pos}
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
