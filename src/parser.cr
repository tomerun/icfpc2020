require "./defs.cr"

macro create_node(var, name, cls)
  if {{ var }} == {{ name }}
    return {{cls}}.new
  end
end

class Parser
  @cs : Array(Char)
  @pos : Int32

  def initialize(row : String)
    @cs = row.chars
    @pos = 0
  end

  def next_token : String
    while @pos < @cs.size && @cs[@pos].whitespace?
      @pos += 1
    end
    start = @pos
    while @pos < @cs.size && !@cs[@pos].whitespace?
      @pos += 1
    end
    return @cs[start...@pos].join
  end

  def parse_assign : Assign?
    if @cs[@pos] != ':'
      return nil
    end
    @pos += 1
    num = next_token.to_i
    assert(@cs[@pos...(@pos + 3)].join == " = ", "#{@cs.join} #{@pos}")
    @pos += 3
    expr = parse_expr().not_nil!
    return Assign.new(num, expr)
  end

  def parse_expr : Node?
    token = next_token
    return nil if token.empty?
    if token[0].number? || token[0] == '-'
      return IntAtom.new(BigInt.new(token))
    elsif token[0] == ':'
      return Var.new(token[1..].to_i)
    elsif token == "ap"
      x0 = parse_expr().not_nil!
      x1 = parse_expr().not_nil!
      return Ap.new(x0, x1)
    else
      create_node(token, "inc", Inc)
      create_node(token, "dec", Dec)
      create_node(token, "add", Add)
      create_node(token, "mul", Mul)
      create_node(token, "div", Div)
      create_node(token, "eq", Eq)
      create_node(token, "lt", LessThan)
      create_node(token, "neg", Neg)
      create_node(token, "s", Scomb)
      create_node(token, "c", Ccomb)
      create_node(token, "b", Bcomb)
      create_node(token, "t", True)
      create_node(token, "f", False)
      create_node(token, "i", Icomb)
      create_node(token, "cons", Cons)
      create_node(token, "car", Car)
      create_node(token, "cdr", Cdr)
      create_node(token, "nil", NilAtom)
      create_node(token, "isnil", IsNil)
      create_node(token, "if0", IfZero)
      return nil
    end
  end
end
