require "big"

NODE_ID = [0i64]

abstract class Node
  @reduced : Node?
  @id : Int64
  property :reduced, :id

  def initialize
    @id = NODE_ID[0]
    NODE_ID[0] += 1
    # puts "node created #{self.class} #{@id}"
  end

  abstract def arity
  abstract def name
  abstract def to_s(io : IO, level : Int)
  abstract def reduce_(ctx : ReduceContext, params : Array(Node))

  def reduce(ctx : ReduceContext)
    if memo = @reduced
      # puts "ret reduced #{self.id} #{@reduced.not_nil!.id} #{self}"
      return memo
    end

    node = self
    while true
      # puts "reduce #{node.id} #{node}"
      if node.reduced
        break if node == node.reduced
        node = node.reduced
      end
      if node.is_a?(Var)
        # puts "reduce var #{node.n}"
        node = ctx.vars[node.n].clone
        next
      end
      if !node.is_a?(Ap)
        break
      end
      args = [] of Node
      args << node.x1.not_nil!
      op = node.x0.not_nil!
      op = node.x0 = op.reduce(ctx).not_nil!
      before = node
      if !op.is_a?(Ap)
        if op.is_a?(Arity1)
          node = op.reduce_(ctx, args)
          if node == before
            break
          end
          next
        end
      else
        args.unshift(op.x1.not_nil!)
        op = op.x0.not_nil!
        if !op.is_a?(Ap)
          if op.is_a?(Arity2) || op.is_a?(Cons)
            node = op.reduce_(ctx, args)
            if node == before
              break
            end
            next
          end
        else
          args.unshift(op.x1.not_nil!)
          op = op.x0.not_nil!
          if op.is_a?(Arity3)
            node = op.reduce_(ctx, args)
            if node == before
              break
            end
            next
          end
        end
      end
      break
    end
    # puts "end reduce #{self.id}"
    @reduced = node
    # if node != self
    #   puts "reduce changed : #{node.class} #{node.id}"
    #   puts String.build { |io| node.to_s(io, 0) }
    # end
    return node
  end

  def to_s(io)
    io << self.name
  end

  def to_s(io, level)
    io << "  " * level << self.name << " #{self.id}" << "\n"
  end

  def clone
    return self
  end
end

abstract class Arity0 < Node
  def arity
    return 0
  end
end

abstract class Arity1 < Node
  def arity
    return 1
  end
end

abstract class Arity2 < Node
  def arity
    return 2
  end
end

abstract class Arity3 < Node
  def arity
    return 3
  end

  def clone
    return self.class.new
  end
end

abstract class ArityN < Node
  def arity
    return 0
  end
end

class IntAtom < Arity0
  getter :v

  def initialize(@v : BigInt)
    super()
  end

  def initialize(v : Int)
    super()
    @v = BigInt.new(v)
  end

  def initialize
    super()
    @v = BigInt.ZERO
  end

  def name
    @v.to_s
  end

  def reduce_(ctx, params)
    return self
  end
end

class Inc < Arity1
  def name
    "inc"
  end

  def reduce_(ctx, params)
    x0 = params[0].reduce(ctx)
    return IntAtom.new(x0.as(IntAtom).v + 1)
  end

  def clone
    return Inc.new
  end
end

class Dec < Arity1
  def name
    "dec"
  end

  def reduce_(ctx, params)
    x0 = params[0].reduce(ctx)
    return IntAtom.new(x0.as(IntAtom).v - 1)
  end

  def clone
    return Dec.new
  end
end

class Add < Arity2
  def name
    "add"
  end

  def reduce_(ctx, params)
    x0 = params[0].reduce(ctx)
    x1 = params[1].reduce(ctx)
    return IntAtom.new(x0.as(IntAtom).v + x1.as(IntAtom).v)
  end

  def clone
    return Add.new
  end
end

class Var < ArityN
  getter :n

  def initialize(@n : Int32)
    super()
  end

  def name
    ":#{@n}"
  end

  def reduce_(ctx, params)
    return self
  end

  def clone
    return Var.new(@n)
  end
end

class Mul < Arity2
  def name
    "mul"
  end

  def reduce_(ctx, params)
    x0 = params[0].reduce(ctx)
    x1 = params[1].reduce(ctx)
    return IntAtom.new(x0.as(IntAtom).v * x1.as(IntAtom).v)
  end

  def clone
    return Mul.new
  end
end

class Div < Arity2
  def name
    "div"
  end

  def reduce_(ctx, params)
    x0 = params[0].reduce(ctx)
    x1 = params[1].reduce(ctx)
    return IntAtom.new(x0.as(IntAtom).v.tdiv(x1.as(IntAtom).v))
  end

  def clone
    return Div.new
  end
end

class Eq < Arity2
  def name
    "eq"
  end

  def reduce_(ctx, params)
    x0 = params[0].reduce(ctx)
    x1 = params[1].reduce(ctx)
    if x0.as(IntAtom).v == x1.as(IntAtom).v
      return True.new
    else
      return False.new
    end
  end

  def clone
    return Eq.new
  end
end

class LessThan < Arity2
  def name
    "lt"
  end

  def reduce_(ctx, params)
    x0 = params[0].reduce(ctx)
    x1 = params[1].reduce(ctx)
    if x0.as(IntAtom).v < x1.as(IntAtom).v
      return True.new
    else
      return False.new
    end
  end

  def clone
    return LessThan.new
  end
end

class Neg < Arity1
  def name
    "neg"
  end

  def reduce_(ctx, params)
    x0 = params[0].reduce(ctx)
    return IntAtom.new(-x0.as(IntAtom).v)
  end

  def clone
    return Neg.new
  end
end

class Ap < Arity0
  property :x0, :x1

  def initialize(@x0 : Node, @x1 : Node)
    super()
  end

  def name
    "ap"
  end

  def to_s(io)
    # special case
    io << "ap " << @x0.to_s << " " << @x1.to_s
  end

  def to_s(io, level)
    io << "  " * level << "ap #{self.id}\n"
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

  def reduce_(ctx, params)
    return self
  end

  def clone
    return Ap.new(@x0.clone, @x1.clone)
  end
end

class Scomb < Arity3
  def name
    "s"
  end

  def reduce_(ctx, params)
    left = Ap.new(params[0], params[2])
    right = Ap.new(params[1], params[2])
    top = Ap.new(left, right)
    return top
  end
end

class Ccomb < Arity3
  def name
    "c"
  end

  def reduce_(ctx, params)
    inner = Ap.new(params[0], params[2])
    outer = Ap.new(inner, params[1])
    return outer
  end
end

class Bcomb < Arity3
  def name
    "b"
  end

  def reduce_(ctx, params)
    inner = Ap.new(params[1], params[2])
    outer = Ap.new(params[0], inner)
    return outer
  end
end

class True < Arity2
  def name
    "t"
  end

  def reduce_(ctx, params)
    return params[0]
  end

  def clone
    return True.new
  end
end

class False < Arity2
  def name
    "f"
  end

  def reduce_(ctx, params)
    return params[1]
  end

  def clone
    return False.new
  end
end

class Icomb < Arity1
  def name
    "i"
  end

  def reduce_(ctx, params)
    return params[0]
  end

  def clone
    return Icomb.new
  end
end

class Cons < Arity3
  def initialize
    super()
  end

  def arity
    return 2
  end

  def name
    "cons"
  end

  def reduce_(ctx, params)
    if params.size == 3
      inner = Ap.new(params[2], params[0])
      outer = Ap.new(inner, params[1])
      return outer
    elsif params.size == 2
      inner = Ap.new(Cons.new, params[0].reduce(ctx).not_nil!)
      outer = Ap.new(inner, params[1].reduce(ctx).not_nil!)
      outer.reduced = outer
      return outer
    else
      return self
    end
  end
end

class Car < Arity1
  def name
    "car"
  end

  def reduce_(ctx, params)
    return Ap.new(params[0], True.new)
  end

  def clone
    return Car.new
  end
end

class Cdr < Arity1
  def name
    "cdr"
  end

  def reduce_(ctx, params)
    return Ap.new(params[0], False.new)
  end

  def clone
    return Cdr.new
  end
end

class NilAtom < Arity1
  def name
    "nil"
  end

  def reduce_(ctx, params)
    if params.size == 1
      return True.new
    else
      return self
    end
  end

  def clone
    return NilAtom.new
  end
end

class IsNil < Arity1
  def name
    "isnil"
  end

  def reduce_(ctx, params)
    return Ap.new(params[0], Ap.new(True.new, Ap.new(True.new, False.new)))
    # x0 = params[0].reduce(ctx)
    # if x0.is_a?(NilAtom)
    #   return True.new
    # else
    #   assert(x0.is_a?(Cons))
    #   return False.new
    # end
    # return self
  end

  def clone
    return IsNil.new
  end
end

class IfZero < Arity3
  def name
    "if0"
  end

  def reduce_(ctx, params)
    x0 = params[0].reduce(ctx)
    if x0.as(IntAtom).v == 0
      return params[1]
    else
      return params[2]
    end
  end
end

class Assign
  getter :num, :node

  def initialize(@num : Int32, @node : Node)
  end

  def to_s(io)
    io << @num << " = " << @node
  end
end

class ReduceContext
  getter :vars
  property :root
  @root : Node?

  def initialize
    @vars = {} of Int32 => Node
  end

  def to_s(io)
    @vars.each do |k, v|
      io << k << " = " << v << "\n"
    end
  end
end

class TypeMismatchError < Exception
end

def assert(x, msg : String? = nil)
  if !x
    raise Exception.new(msg)
  end
end
