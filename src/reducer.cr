require "./defs.cr"
require "./parser.cr"

class Reducer
  def execute(io)
    vars = {} of Int32 => Node
    protocol = nil : Node?
    io.each_line do |line|
      parser = Parser.new(line)
      if line[0] == ':'
        assignment = parser.parse_assign.not_nil!
        vars[assignment.var.n] = assignment.node.reduce.not_nil!
      else
        proto_name = parser.next_token
        puts "protocol name: #{proto_name}"
        parser.next_token # skip " = "
        protocol = parser.parse_expr.not_nil!
        # protocol = protocol.reduce.not_nil!
        puts String.build { |io| protocol.to_s(io, 0) }
      end
    end
    # vars.each do |k, v|
    #   puts k
    #   puts v
    #   puts v.inspect
    # end
    pos = [[0, 0], [2, 3], [1, 2], [3, 2], [4, 0]]
    state = NilAtom.new
    pos.each do |p|
      data = Cons.new(IntAtom.new(p[0]), Cons.new(IntAtom.new(p[1]), NilAtom.new))
      top1 = Ap.new(protocol.clone, state)
      top2 = Ap.new(top1, data)
      res = top2.reduce.not_nil!
      puts String.build { |io| res.to_s(io, 0) }
      flag = res.as(Cons).car
      puts "flag:#{flag}"
      state = res.as(Cons).cdr.as(Cons).car
      puts "state:#{state}"
      data = res.as(Cons).cdr.as(Cons).cdr
      puts "data:#{data}"
    end
  end
end

reducer = Reducer.new
reducer.execute(ARGF)
