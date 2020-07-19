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
    else
      io << "11"
      mod(l[0], io)
      mod(l[1..], io)
    end
  end
end

def mod(l : List) : String
  return String.build do |io|
    mod(l, io)
  end
end

def demod(str : String, pos : Int32, depth : Int32) : Tuple(Node, Int32)
  if str[pos] == '1' && str[pos + 1] == '1'
    car, pos = demod(str, pos + 2, 0)
    cdr, pos = demod(str, pos, depth + 1)
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
  return demod(str, 0, 0)[0]
end
