require "big"

abstract class Node
  abstract def name
end

abstract class Arity0 < Node
  def param_count
    return 0
  end

  def param_full?
    return true
  end

  def to_s(io)
    io << self.name
  end
end

abstract class Arity1 < Node
  getter :x0

  def initialize(@x0 : Node? = nil)
  end

  def param_count
    return @x0.nil? ? 0 : 1
  end

  def param_full?
    return !@x0.nil?
  end

  def to_s(io)
    if !@x0
      io << self.name
    else
      io << "ap #{self.name} " << @x0
    end
  end
end

abstract class Arity2 < Node
  getter :x0, :x1

  def initialize(@x0 : Node? = nil, @x1 : Node? = nil)
  end

  def param_count
    return @x0.nil? ? 0 : @x1.nil? ? 1 : 2
  end

  def param_full?
    return !@x1.nil?
  end

  def to_s(io)
    if !@x0
      io << self.name
    elsif !@x1
      io << "ap #{self.name} " << @x0
    else
      io << "ap ap #{self.name} " << @x0 << " " << @x1
    end
  end
end

abstract class Arity3 < Node
  getter :x0, :x1, :x2

  def initialize(@x0 : Node? = nil, @x1 : Node? = nil, @x2 : Node? = nil)
  end

  def param_count
    return @x0.nil? ? 0 : @x1.nil? ? 1 : @x2.nil? ? 2 : 3
  end

  def param_full?
    return !@x2.nil?
  end

  def to_s(io)
    if !@x0
      io << self.name
    elsif !@x1
      io << "ap #{self.name} " << @x0
    elsif !@x2
      io << "ap ap #{self.name} " << @x0 << " " << @x1
    else
      io << "ap ap ap #{self.name} " << @x0 << " " << @x1 << " " << @x2
    end
  end
end

class IntAtom < Arity0
  getter :v

  def initialize(@v : BigInt)
  end

  def initialize(v : Int)
    @v = BigInt.new(v)
  end

  def to_s(io)
    io << @v
  end

  def name
    @v.to_s
  end
end

class Inc < Arity1
  def name
    "inc"
  end
end

class Dec < Arity1
  def name
    "dec"
  end
end

class Add < Arity2
  def name
    "add"
  end
end

class Var < Arity0
  getter :n

  def initialize(@n : Int32)
  end

  def name
    ":#{@n}"
  end
end

class Mul < Arity2
  def name
    "mul"
  end
end

class Div < Arity2
  def name
    "div"
  end
end

class Eq < Arity2
  def name
    "eq"
  end
end

class LessThan < Arity2
  def name
    "lt"
  end
end

class Neg < Arity1
  def name
    "neg"
  end
end

class Ap < Arity2
  def name
    "ap"
  end

  def to_s(io)
    # special case
    io << "ap " << @x0 << " " << @x1
  end
end

class Scomb < Arity3
  def name
    "s"
  end
end

class Ccomb < Arity3
  def name
    "c"
  end
end

class Bcomb < Arity3
  def name
    "b"
  end
end

class True < Arity2
  def name
    "t"
  end
end

class False < Arity2
  def name
    "f"
  end
end

class Pwr2 < Arity1
  def name
    "pwr2"
  end
end

class Icomb < Arity1
  def name
    "i"
  end
end

class Cons < Arity3
  def car
    @x0
  end

  def cdr
    @x1
  end

  def name
    "cons"
  end
end

class Car < Arity1
  def name
    "car"
  end
end

class Cdr < Arity1
  def name
    "cdr"
  end
end

class NilAtom < Arity1
  def name
    "nil"
  end
end

class IsNil < Arity1
  def name
    "isnil"
  end
end

class IfZero < Arity3
  def name
    "if0"
  end
end

class Assign
  getter :var, :node

  def initialize(@var : Var, @node : Node)
  end

  def to_s(io)
    io << @var << " = " << @node
  end
end

class TypeMismatchError < Exception
end

def assert(x, msg : String? = nil)
  if !x
    raise Exception.new(msg)
  end
end
