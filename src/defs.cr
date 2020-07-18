require "big"

abstract class Node
  abstract def name
  abstract def to_s(io : IO, level : Int)
  abstract def clone
end

abstract class Arity0 < Node
  def param_count
    return 0
  end

  def param_full?
    return true
  end

  def add_param(param)
    raise Exception.new("invalid param set:#{param}")
  end

  def to_s(io)
    io << self.name
  end

  def to_s(io, level)
    io << "  " * level << self.name << " #{self.hash}" << "\n"
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

  def add_param(param)
    raise Exception.new("invalid param set:#{param}") if param_full?
    @x0 = param
  end

  def to_s(io)
    if !@x0
      io << self.name
    else
      io << "ap #{self.name} " << @x0
    end
  end

  def to_s(io, level)
    if x0 = @x0
      io << "  " * level << "ap" << "\n"
      io << "  " * (level + 1) << self.name << " #{self.hash}" << "\n"
      x0.to_s(io, level + 1)
    else
      io << "  " * level << self.name << " #{self.hash}" << "\n"
    end
  end

  def clone
    return self.class.new(@x0.clone)
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

  def add_param(param)
    raise Exception.new("invalid param set:#{param}") if param_full?
    if !@x0
      @x0 = param
    else
      @x1 = param
    end
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

  def to_s(io, level)
    if x1 = @x1
      io << "  " * level << "ap" << "\n"
      io << "  " * (level + 1) << "ap" << "\n"
      io << "  " * (level + 2) << self.name << " #{self.hash}" << "\n"
      @x0.not_nil!.to_s(io, level + 2)
      x1.to_s(io, level + 1)
    elsif x0 = @x0
      io << "  " * level << "ap" << "\n"
      io << "  " * (level + 1) << self.name << " #{self.hash}" << "\n"
      x0.to_s(io, level + 1)
    else
      io << "  " * level << self.name << " #{self.hash}" << "\n"
    end
  end

  def clone
    return self.class.new(@x0.clone, @x1.clone)
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

  def add_param(param)
    raise Exception.new("invalid param set:#{param}") if param_full?
    if !@x0
      @x0 = param
    elsif !@x1
      @x1 = param
    else
      @x2 = param
    end
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

  def to_s(io, level)
    if x2 = @x2
      io << "  " * level << "ap" << "\n"
      io << "  " * (level + 1) << "ap" << "\n"
      io << "  " * (level + 2) << "ap" << "\n"
      io << "  " * (level + 3) << self.name << " #{self.hash}" << "\n"
      @x0.not_nil!.to_s(io, level + 3)
      @x1.not_nil!.to_s(io, level + 2)
      x2.to_s(io, level + 1)
    elsif x1 = @x1
      io << "  " * level << "ap" << "\n"
      io << "  " * (level + 1) << "ap" << "\n"
      io << "  " * (level + 2) << self.name << " #{self.hash}" << "\n"
      @x0.not_nil!.to_s(io, level + 2)
      x1.to_s(io, level + 1)
    elsif x0 = @x0
      io << "  " * level << "ap" << "\n"
      io << "  " * (level + 1) << self.name << " #{self.hash}" << "\n"
      x0.to_s(io, level + 1)
    else
      io << "  " * level << self.name << " #{self.hash}" << "\n"
    end
  end

  def clone
    return self.class.new(@x0.clone, @x1.clone, @x2.clone)
  end
end

class IntAtom < Arity0
  getter :v

  def initialize(@v : BigInt)
  end

  def initialize(v : Int)
    @v = BigInt.new(v)
  end

  def initialize
    @v = BigInt.ZERO
  end

  def to_s(io)
    io << @v
  end

  def to_s(io, level)
    io << "  " * level << @v << "\n"
  end

  def name
    @v.to_s
  end

  def reduce
    return self
  end

  def clone
    return IntAtom.new(@v)
  end
end

class Inc < Arity1
  def name
    "inc"
  end

  def reduce
    if x0 = @x0
      @x0 = x0.reduce
    end
    if (x0 = @x0) && x0.is_a?(IntAtom)
      return IntAtom.new(x0.v + 1)
    else
      return self
    end
  end
end

class Dec < Arity1
  def name
    "dec"
  end

  def reduce
    if x0 = @x0
      @x0 = x0.reduce
    end
    if (x0 = @x0) && x0.is_a?(IntAtom)
      return IntAtom.new(x0.v - 1)
    else
      return self
    end
  end
end

class Add < Arity2
  def name
    "add"
  end

  def reduce
    if x0 = @x0
      @x0 = x0.reduce
    end
    if x1 = @x1
      @x1 = x1.reduce
    end
    if (x0 = @x0) && x0.is_a?(IntAtom) && (x1 = @x1) && x1.is_a?(IntAtom)
      return IntAtom.new(x0.v + x1.v)
    else
      return self
    end
  end
end

class Var < Arity0
  getter :n

  def initialize(@n : Int32)
  end

  def name
    ":#{@n}"
  end

  def reduce
    return self
  end

  def clone
    return self.class.new(@n)
  end
end

class Mul < Arity2
  def name
    "mul"
  end

  def reduce
    if x0 = @x0
      @x0 = x0.reduce
    end
    if x1 = @x1
      @x1 = x1.reduce
    end
    if (x0 = @x0) && x0.is_a?(IntAtom) && (x1 = @x1) && x1.is_a?(IntAtom)
      return IntAtom.new(x0.v * x1.v)
    else
      return self
    end
  end
end

class Div < Arity2
  def name
    "div"
  end

  def reduce
    if x0 = @x0
      @x0 = x0.reduce
    end
    if x1 = @x1
      @x1 = x1.reduce
    end
    if (x0 = @x0) && x0.is_a?(IntAtom) && (x1 = @x1) && x1.is_a?(IntAtom)
      return IntAtom.new(x0.v.tdiv(x1.v))
    else
      return self
    end
  end
end

class Eq < Arity2
  def name
    "eq"
  end

  def reduce
    if x0 = @x0
      @x0 = x0.reduce
    end
    if x1 = @x1
      @x1 = x1.reduce
    end
    if (x0 = @x0) && x0.is_a?(IntAtom) && (x1 = @x1) && x1.is_a?(IntAtom)
      if x0.v == x1.v
        return True.new
      else
        return False.new
      end
    end
    if (x0 = @x0) && x0.is_a?(Var) && (x1 = @x1) && x1.is_a?(Var)
      if x0.n == x1.n
        return True.new
      end
    end
    return self
  end
end

class LessThan < Arity2
  def name
    "lt"
  end

  def reduce
    if x0 = @x0
      @x0 = x0.reduce
    end
    if x1 = @x1
      @x1 = x1.reduce
    end
    if (x0 = @x0) && x0.is_a?(IntAtom) && (x1 = @x1) && x1.is_a?(IntAtom)
      if x0.v < x1.v
        return True.new
      else
        return False.new
      end
    end
    return self
  end
end

class Neg < Arity1
  def name
    "neg"
  end

  def reduce
    if x0 = @x0
      @x0 = x0.reduce
    end
    if (x0 = @x0) && x0.is_a?(IntAtom)
      return IntAtom.new(-x0.v)
    else
      return self
    end
  end
end

class Ap < Arity2
  def name
    "ap"
  end

  def to_s(io)
    # special case
    io << "ap " << @x0.to_s << " " << @x1.to_s
  end

  def to_s(io, level)
    io << "  " * level << "ap #{self.hash}\n"
    if x0 = @x0
      x0.to_s(io, level + 1)
    else
      io << "  " * (level + 1) << "[empty]\n"
    end
    if x1 = @x1
      x1.to_s(io, level + 1)
    else
      io << "  " * (level + 1) << "[empty]\n"
    end
  end

  def reduce
    if x0 = @x0
      @x0 = x0 = x0.reduce
      if x0 && !x0.is_a?(Ap) && !x0.param_full?
        x0.add_param(@x1)
        x0 = x0.reduce
        return x0
      end
    end
    if x1 = @x1
      @x1 = x1.reduce
    end
    return self
  end
end

class Scomb < Arity3
  def name
    "s"
  end

  def reduce
    if x0 = @x0
      @x0 = x0.reduce
    end
    if x1 = @x1
      @x1 = x1.reduce
    end
    if x2 = @x2
      @x2 = x2.reduce
    end
    if @x2
      left = Ap.new(@x0, @x2)
      right = Ap.new(@x1, @x2)
      top = Ap.new(left, right)
      return top.reduce
    end
    return self
  end
end

class Ccomb < Arity3
  def name
    "c"
  end

  def reduce
    if x0 = @x0
      @x0 = x0.reduce
    end
    if x1 = @x1
      @x1 = x1.reduce
    end
    if x2 = @x2
      @x2 = x2.reduce
    end
    if @x2
      inner = Ap.new(@x0, @x2)
      outer = Ap.new(inner, @x1)
      return outer.reduce
    end
    return self
  end
end

class Bcomb < Arity3
  def name
    "b"
  end

  def reduce
    if x0 = @x0
      @x0 = x0.reduce
    end
    if x1 = @x1
      @x1 = x1.reduce
    end
    if x2 = @x2
      @x2 = x2.reduce
    end
    if @x2
      inner = Ap.new(@x1, @x2)
      outer = Ap.new(@x0, inner)
      return outer.reduce
    end
    return self
  end
end

class True < Arity2
  def name
    "t"
  end

  def reduce
    if x0 = @x0
      return x0.reduce
    end
    return self
  end
end

class False < Arity2
  def name
    "f"
  end

  def reduce
    if x1 = @x1
      return x1.reduce
    end
    return self
  end
end

class Pwr2 < Arity1
  def name
    "pwr2"
  end

  def reduce
    if x0 = @x0
      @x0 = x0.reduce
    end
    if (x0 = @x0) && x0.is_a?(IntAtom)
      return IntAtom.new(BigInt.new(1) << x0.v)
    else
      return self
    end
  end
end

class Icomb < Arity1
  def name
    "i"
  end

  def reduce
    if x0 = @x0
      return x0.reduce
    else
      return self
    end
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

  def reduce
    if x0 = @x0
      @x0 = x0.reduce
    end
    if x1 = @x1
      @x1 = x1.reduce
    end
    # if @x2
    #   inner = Ap.new(@x2, @x0)
    #   outer = Ap.new(inner, @x1)
    #   return outer.reduce
    # end
    return self
  end
end

class Car < Arity1
  def name
    "car"
  end

  def reduce
    if @x0
      return Ap.new(@x0, True.new).reduce
    else
      return self
    end
  end
end

class Cdr < Arity1
  def name
    "cdr"
  end

  def reduce
    if @x0
      return Ap.new(@x0, False.new).reduce
    else
      return self
    end
  end
end

class NilAtom < Arity1
  def name
    "nil"
  end

  def reduce
    if @x0
      return True.new
    else
      return self
    end
  end
end

class IsNil < Arity1
  def name
    "isnil"
  end

  def reduce
    if x0 = @x0
      @x0 = x0.reduce
    end
    if (x0 = @x0) && x0.is_a?(NilAtom)
      return True.new
    elsif (x0 = @x0) && x0.is_a?(Cons)
      if x0.car && x0.cdr && !x0.x2
        return False.new
      end
    end
    return self
  end
end

class IfZero < Arity3
  def name
    "if0"
  end

  def reduce
    if x0 = @x0
      @x0 = x0.reduce
    end
    if x1 = @x1
      @x1 = x1.reduce
    end
    if x2 = @x2
      @x2 = x2.reduce
    end
    if (x0 = @x0) && x0.is_a?(IntAtom)
      if x0.v == 0
        return @x1 if @x1
      else
        return @x2 if @x2
      end
    end
    return self
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
