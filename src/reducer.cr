require "./defs.cr"
require "./modem.cr"
require "./parser.cr"
require "http/client"

API_URL = URI.parse("https://icfpc2020-api.testkontur.ru/aliens/send?apiKey=#{ENV["API_KEY"]}")

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
    data = Ap.new(Ap.new(Cons.new, IntAtom.new(0)), IntAtom.new(0))
    click_pos = [] of Tuple(Int32, Int32)
    # received_history = ["1101100001110101101100011110111000011111111111011000011101011011001000011110101101100001110110001100001111110111000010000110111010000000001111110101111111101100001110101111011100011000001110000110001111010010111101110110011101101110000111101101101010110110000100110101101110010000001101100001001100001111110101101100001111110110001100001011000011000111101001011110111001101110110111000101000110111000010100110110000100110101101110100000001101100010001100000000111101100001111111110110000111010111101110001011100111000011001111110100010011000011111011101100110111011100001111011011010101101100001001101011011100100000011011000010011111101011110110000110100001000000111111010110110000111111011000101110101100001100011110110001001011110111001101101110111000101000110111000010100110110000100110101101110100000001101100010001111110101111101000010100000000000111101100010111111110110000111010111101110001010100111000011011111110100100011000101111011101100110011011100001111011011010101101100001001101011011100100000011011000010011111101011110110000110100001000000111111010110110000111111011000101010101100001100011110110010001011110111001101100110111000101000110111000010100110110000100110101101110100000001101100010001111110101111101000010100000000000111101100011111111110110000111010111101110001001010111000011101111110100101011000101111011101100110011011100001111011011010101101100001001101011011100100000011011000010011000011111101011011000011111101100010010110110000110011111011001011010000111110111001101011110111000101000110111000010100110110000100110101101110100000001101100010001111110101111010011000010000000000111101100100111111110110000111010111101110001000000111000100000111110100101011000111111011101100101111011100001111011011010101101100001001101100111110111001000000110110000100111111010111110100001101000010000001111110101101100001111110110001000001011000011011111101100101101000101111011100110101011011100010100011011100001010011011000010011011100001110011011101000000011011000100011111101100010111101110000111110111000011111110111000101000110111000100111110110010000111101011110110000101100001000000000011110110010111111111011000011101011110111000011011011100010001111111010010101100011111101110110010101101110000111101101101010110110000100110110010111011100100000011011000010011111101011111010000110100001000000111111010110110000111111011000011011101100001111011110110010110100011111101110011010011101110001010001101110000101001101100001001101110000100001101110100000001101100010001111110101111011000010110000100000000001111011001101111111101100001110101111011100001011101110001001101111101001000110001111110111011001001110111000011110110110101011011000010011011000111101110010000001101100001001111110101111101000011010000100000011111101011011000011111101100001011010110001000001111011001011010001011110111001101001110111000101000110111000010100110110000100110101101110100000001101100010001100000000111101100111111111110110000111010111101110000100110111000101001111110100100011000111111011101100100011011100001111011011010101101100001001101100001110111001000000110110000100111111010111101010100001000000111111010110110000111111011000010000101100010000111110110011010100001111101110011010001101110001010001101110000101001101100001001101011011101000000011011000100011111101011111010000101000000000001111011010001111111101100001110101111011100001000001110001011001111101000110110001111110111011000111110111000011110110110101011011000010011010110111001000000110110000100111111010111110100001101000010000001111110101101100001111110101010101100010000111110110011001011110111001101000110111000101000110111000010100110110000100110101101110100000001101100010001100000000111101101001111111110110000111010111101101110011100010111111111010001001100011111101110110001101101110000111101101101010110110000100110101101110010000001101100001001111110101111101000011010000100000011111101011011000011111101001011011000100001111101100101010111101110011001111101110001010001101110000101001101100001001101011011101000000011011000100011111101011110110000101100001000000000011110110101011111111011000011101011110110110101110001100011111101000010110001011110111011000101110111000011110110110101011011000010011010110111001000000110110000100111111010111110100001010000000111111010110110000111110101011000011111111101100101011000101111011100110011011011100010100011011100001010011011000010011010110111010000000110110001000111111010111101010100001000000000011110110101111111111011000011101011110110110101110001100101111010011000011111011101100010011011100001111011011010101101100001001101100011110111001000000110110000100111111010111110100001010000000111111010110110000111110110010110110000111001111011001010110001111110111001100110110111000101000110111000010100110110000100110111000010100110111010000000110110001000111111011000101111011011000111000110010110111000101000110111000010110110110010000000000001111011011001111111101100001110101111011011100111000110010111101100001010111101110110000111101110000111101101101010110110000100110110101011011100100000011011000010011111101011111010000101000000011111101011011000011111011010101011000011000111101100101011001001111011100110011011011100010100011011100001010011011000010011011100010100011011101000000011011000100011111101100010111101101101011100011001011011100010100011011100010011011011001000000000000111101101101111111110110000111010111101110000100000111000110001111101100010101000011111011101100001011011100001111011011010101101100001001101110001100101101110010000001101100001001111110110001011110110111110110000100111101110000111101101110000101011101100100001111010111110100001010000000111111010110110000111110110111010110000100101111011001000110011011110111001100101110111000101000110111000010100110110000100110111001001001110111010000000110110001000111111011000101111011011110111000110001110111000101000110111000110011110110010000111101011110110000110100001000000000011110110111011111111011000011101011110111000010010011100010111011110110001010100011111101110101010101101110000111101101101010110110000100110111001000000110111001000000110110000100111111011000101111011100001001010101011110111000011000110111000010000110110010000111101011110100110000100000011111101011011000011111011100001001010101011111101100100011001111111011100110010111011100010100011011100001010011011000010011011100110110111011101000000011011000100011111101100010111101110000100100111000101111110111000101000110111000111111110110010000000000001111011011111111111101100001110101111011100001010001110001010101111011000101010010011110111001110000110111000011110110110101011011000010011011100100000011011100100000011011000010011000011111101011011000011111011100001010110100011111101100011011010001111011100101110011011100010100011011100001010011011000010011011101000000011011101000000011011000100011111101100010111101110000101000111000101010110111000100111110111001000100110110010000111101011110101010000100000000001111011100001000011111111011000011101011110111000010110011100010010111110110001010100101111101110010111101101110000111101101101010110110000100110111001000000110111001000000110110000100110000111111010110110000111110111000010110011001001111011000010110011111110111001010011110111000101000110111000010100110110000100110111010000000110111010000000110110001000111111011000101111011100001011001110001001011101110000101001101110000111001101100100001111010111101100001011000010000000000111101110000100011111111101100001110101111011100001100101110001000001111011000111010010111110111001001100110111000011110110110101011011000010011011100100000011011100100000011011000010011111101100010111101110000101100110101111011010101101100010110110010000111101011111010000110100001000000111111010110110000111110111000010111011011001111011000010110100011110111001001010110111000101000110111000010100110110000100110111010000000110111010000000110110001000111111011000101111011100001100001110000111111101110000101001101110001001001101100100001111010111110100001101000010000000000111101110000100101111111101100001110101111011100001110001110000110011111011000111010011111110111000111011110111000011110110110101011011000010011011100100000011011100100000011011000010011111101100010111101110000101110111000010100110110101011011100001101011011001000011110101111010011000010000001111110101101100001111101110000101100111000010101111110100001011010011111011100011101111011100010100011011100001010011011000010011011101000000011011101000000011011000100011111101100010111101110000111000111000011010110111000010100110111000100011110110010000111101011110110000110100001000000000011110111000010011111111110110000111010111101110000111110111000010011111101100011101001101111011100010011011011100001111011011010101101100001001101110010000001101110010000001101100001001111110110001011110111000010100011100001111011011010101101110000101001101100100001111010111110100001101000010000001111110101101100001111101110000100110111000011101111110100011011010001111011100010110111011100010100011011100001010011011000010011011101000000011011101000000011011000100011111101100010111101110000111100111000010010110111000010100110111000110010110110010000111101011110110000101100001000000000011110111000010100111111110110000111010111101110001000010110111011110110001010100101111101110001000111101110000111101101101010110110000100110111001000000110111001000000110110000100111111010111101010100001000000111111010110110000111110110111101110001000111111101001000110011011110111000100100110111000101000110111000010100110110000100110111010000000110111010000000110110001000111111011000101111011100010000101101101110111000010100110111000010010110110010000111101011110110000101100001000000000011110111000010101111111110110000111010111101110001000110110101011110110001010100100111101110001000101101110000111101101101010110110000100110111000111110110111001000000110110000100111111010111110100001101000010000001111110101101100001111101101010011100010011111111010010101100100111101110001000111101110001010001101110000101001101100001001101110011101001101110100000001101100010001111110101111011000010110000100000000001111011100001011011111111011000011101011110111000100101011001111111011000101010001111110111000011010110111000011110110110101011011000010011011100100000011011100100000011011000010011111101011111010000110100001000000111111010110110000111110110010001110001010011111101001100110001011110111000011010110111000101000110111000010100110110000100110111010000000110111010000000110110001000111111011000101111011100010010001100110110111000100000110111000101110110110010000111101011110110000101100001000000000011110111000010111111111110110000111010111101110001001010110001111110101010010011110111000010110110111000011110110110101011011000010011011100100000011011100100000011011000010011111101011110110000101100001000000111111010110110000111111010000101110001010111111101001010110001011110111000010001110111000101000110111000010100110110000100110111010000000110111010000000110110001000111111011000101111011100010011001100100110111000010100110111000010110110110010000111101011111010000110100001000000000011110111000011000111111110110000111010111101110001001011010000111110101010010011110111000010101110111000011110110110101011011000010011011100100000011011100100000011011000010011111101011111010000101000000011111101011011000011111101001100111000101100111110100101011000011111011100001000111011100010100011011100001010011011000010011011101000000011011101000000011011000100011111101100010111101110001001001010000111011100001010011011010001101100100000000000011110111000011001111111110110000111010111101110001001001010010111111010000110100100111101110000101011101110000111101101101010110110000100110111000111101110111001000000110110000100110000111111010110110000111111010110001110001011011111101001100110000111110110100011011100010100011011100001010011011000010011011101000000011011101000000011011000100011111101100010111101110001001001010010111011100001010011011001111101100100001111010111101100001101000010000000000111101110000110101111111101100001110101111011100010001110101010111110100001101001011111011100001010011011100001111011011010101101100001001101110001110111101110010000001101100001001111110101111101000010110000100000011111101011011000011111101100001001001110001011011111101001100101111011010001101110001010001101110000101001101100001001101110100000001101110100000001101100010001111110110001011110111000100010101010011101110000101001101100011110110010000000000001111011100001101111111111011000011101011110111000100001101011111111101000101010010111110111000010100110111000011110110110101011011000010011011100011000111011100100000011011000010011000011111101011011000011111101100001100001110001011001111101001101010000111110110100011011100010100011011100001010011011000010011011100110110011011101000000011011000100011000000001111011100001110011111111011000011101011110111000011110101100001010011111010001110100101111101011011100001011011011010101101100001001101110010000001101110010000001101100001001100001111110101101100001111110110000111010111000101001111110100101101000111111010110111000100111110111000010100110110000100110111010000000110111010000000110110001000111111011000101111011100001111010110000101001101110001010001101110001101011101100100001111010111110100001011000010000000000111101110000111011111111101100001110101111011100001101010110000110011111101001001010010111110101101110000101101101101010110110000100110111000110110110111001000000110110000100110000111111010110110000111111011000100010011100010010111111010010110100100111101011011100010011111011100001010011011000010011011100110110011011101000000011011000100011000000001111011100001111011111111011000011101011110111000010101101100001111011111010010110100101111101011010110110001111011000010011011100100000011011100100000011011000010011000011111101011011000011111101100010011101110001000001111101001011010010111110101101110001001111101110000101001101100001001101110011111111101110100000001101100010001111110110001011110111000010101101100001111011011100010011111011100011000111011001000000000000111101110000111111111111101100001110101111011100001000010110001000101111101001011010010011110101101011011000111101100001001101110001111011101110010000001101100001001100001111110101101100001111110110001010110111000011011111110100100101001011111010110111000100111110111000010100110110000100110111001101011110111010000000110110001000110000000011110111000100000111111110110000111010111101101011101100010010111111010010110100011111101011010110101101000110111001000000110111001000000110110000100110000111111010110110000111111011000101110011100001011011111010001110100101111101011011100010011111011100001010011011000010011011100111111011011101000000011011000100011111101100010111101101011101100010010111011100010011111011100011010011011001000000000000000000"] * 1
    click_pos = [[0, 0], [-3, -3], [-3, -3], [-3, -3], [-3, -3], [-3, -3], [-3, -3], [0, 0], [8, 4], [2, -8], [3, 6], [0, -14], [-4, 10], [9, -3], [-4, 10], [0, 0],
                 [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0],
                 # [18, 0],
    ]

    while true
      if click_pos.empty?
        # search(protocol, state)
        puts "input next pos"
        pos = read_line.split.map(&.to_i)
      else
        pos = click_pos.shift
      end

      data = Ap.new(Ap.new(Cons.new, IntAtom.new(pos[0])), IntAtom.new(pos[1]))
      while true
        reduced = execute_single(protocol.not_nil!, state, data)
        flag = reduced.as(Ap).x0.as(Ap).x1.as(IntAtom)
        state = reduced.as(Ap).x1.as(Ap).x0.as(Ap).x1
        data = reduced.as(Ap).x1.as(Ap).x1.as(Ap).x0.as(Ap).x1

        puts "flag:#{flag.v}"
        puts "state:#{get_list(state)}"
        if flag.v == 0
          puts "click #{pos}"
          draw(get_list(data))
          break
        end
        puts "data: #{get_list(data)}"
        # if !received_history.empty?
        #   received = received_history.shift
        # else
        received = send(data)
        #   received = read_line
        # end
        data = demod(received)
        puts "new_data:#{get_list(data)}"
        # puts String.build { |io| data.to_s(io, 0) }
      end
      # puts "input next pos"
      # y, x = read_line.split.map(&.to_i)
      # puts "click (#{y},#{x})"
      # data_node = Ap.new(Ap.new(Cons.new, IntAtom.new(x)), IntAtom.new(y))
    end
  end

  def search(protocol, state)
    prev_state = get_list(state)
    -60.upto(3) do |y|
      -7.upto(45) do |x|
        data = Ap.new(Ap.new(Cons.new, IntAtom.new(x)), IntAtom.new(y))
        puts "click #{x} #{y}"
        while true
          reduced = execute_single(protocol.not_nil!, state, data)
          flag = reduced.as(Ap).x0.as(Ap).x1.as(IntAtom)
          state = reduced.as(Ap).x1.as(Ap).x0.as(Ap).x1
          data = reduced.as(Ap).x1.as(Ap).x1.as(Ap).x0.as(Ap).x1
          if flag.v == 0
            # puts "click #{pos}"
            # draw(data)
            break
          end
          puts "send #{mod(data)}"
          received = read_line
          data = demod(received)
          puts "new_data:#{get_list(data)}"
        end
        if get_list(state) != prev_state
          puts "state:#{get_list(state)}"
          puts "click #{y} #{x}"
          draw(get_list(data))
          break
        end
      end
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

  def send(data : Node)
    body = mod(data)
    puts "send:#{body}"
    res = HTTP::Client.post(API_URL, body: body)
    puts "received:#{res.body}"
    return res.body
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
  File.open("picture.txt", "w") do |f|
    f.puts "(#{minx},#{miny})-(#{maxx},#{maxy})"
    screen = Array.new(maxy - miny + 1) { Array.new(maxx - minx + 1, false) }
    pos.each do |p|
      screen[p[0] - miny][p[1] - minx] = true
    end
    top = "     "
    x_pos = minx
    while top.size < maxx - minx + 7
      add = x_pos.to_s
      add += " " * (10 - add.size)
      top += add
      x_pos += 10
    end
    f.puts top
    miny.upto(maxy) do |y|
      f.printf("% 4d ", y)
      screen[y - miny].each do |pixel|
        f.print(pixel ? "#" : " ")
      end
      f.puts
    end
  end
end

reducer = Reducer.new
reducer.execute(ARGF)
