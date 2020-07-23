require "./defs.cr"
require "./modem.cr"
require "./parser.cr"
require "http/client"
require "stumpy_png"
include StumpyPNG

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
    click_pos = [[0, 0], [-3, -3], [-3, -3], [-3, -3], [-3, -3], [-3, -3], [-3, -3], [0, 0], [8, 4], [2, -8], [3, 6], [0, -14], [-4, 10], [9, -3], [-4, 10], [0, 0],
                 [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0],
                 [18, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0],
    ]

    while true
      if click_pos.empty?
        # search(protocol, state)
        puts "input next pos"
        pos = read_line.split.map(&.to_i)
        next if pos.empty?
      else
        pos = click_pos.shift
      end

      data = make_cons(IntAtom.new(pos[0]), IntAtom.new(pos[1]))
      while true
        reduced = execute_single(protocol.not_nil!, state, data)
        flag = reduced.as(Ap).x0.as(Ap).x1.as(IntAtom)
        state = reduced.as(Ap).x1.as(Ap).x0.as(Ap).x1
        data = reduced.as(Ap).x1.as(Ap).x1.as(Ap).x0.as(Ap).x1

        puts "flag:#{flag.v}"
        puts "state:#{print_state(state)}"
        if flag.v == 0
          puts "click #{pos}"
          draw(get_list(data))
          break
        end
        puts "data: #{get_list(data)}"
        received = send(data)
        #   received = read_line
        data = demod(received)
        puts "new_data:#{get_list(data)}"
        # puts String.build { |io| data.to_s(io, 0) }
      end
    end
  end

  def make_cons(car : Node, cdr : Node)
    return Ap.new(Ap.new(Cons.new, car), cdr)
  end

  def search(protocol, state)
    prev_state = get_list(state)
    -60.upto(3) do |y|
      -7.upto(45) do |x|
        data = make_cons(IntAtom.new(x), IntAtom.new(y))
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

  def print_state(state : Node)
    print_state(get_list(state), 0)
    puts
  end

  def print_state(state : List, depth)
    print "  " * depth
    if state.is_a?(Array(List))
      if depth < 5 && !state.empty? && (state.size > 8 || state.any? { |e| e.is_a?(Array(List)) && !e.empty? })
        puts "["
        state.each do |e|
          print_state(e, depth + 1)
        end
        puts "  " * depth + "]"
      else
        print_flat(state)
        puts ","
      end
    else
      puts state.to_s + ","
    end
  end

  def print_flat(state : List)
    case state
    when Array(List)
      print "["
      (state.size - 1).times do |i|
        print_flat(state[i])
        print ","
      end
      if !state.empty?
        print_flat(state[-1])
      end
      print "]"
    else
      print state
    end
  end
end

def draw(data : Array(List))
  pos = Array(Array(Tuple(Int32, Int32))).new
  data.each do |e|
    ps = [] of Tuple(Int32, Int32)
    e.as(Array(List)).each do |p|
      x = p.as(Array(List))[0].as(BigInt).to_i
      y = p.as(Array(List))[1].as(BigInt).to_i
      ps << {y, x}
    end
    pos << ps
  end
  minx = 0
  maxx = 0
  miny = 0
  maxy = 0
  pos.flatten.each do |p|
    minx = {minx, p[1]}.min
    maxx = {maxx, p[1]}.max
    miny = {miny, p[0]}.min
    maxy = {maxy, p[0]}.max
  end

  w = maxx - minx + 1
  h = maxy - miny + 1
  scale = 5
  canvas = Canvas.new(w * scale, h * scale)
  puts "(#{minx},#{miny})-(#{maxx},#{maxy})"
  puts "ps size: #{pos.size}"
  colors = [
    RGBA::BLACK,
    RGBA.from_rgba8(*RGBA::RED.to_rgb8, 172),
    RGBA.from_rgba8(*RGBA::BLUE.to_rgb8, 172),
    RGBA.from_rgba8(*RGBA::GREEN.to_rgb8, 172),
    RGBA.from_rgba8(*RGBA::HOTPINK.to_rgb8, 172),
  ]
  pos.each.with_index do |ps, pi|
    color = pi < colors.size ? colors[pi] : colors[0]
    ps.each do |p|
      x = p[1] - minx
      y = p[0] - miny
      scale.times do |i|
        scale.times do |j|
          xp = x * scale + i
          yp = y * scale + j
          canvas[xp, yp] = color.over(canvas[xp, yp])
        end
      end
    end
  end
  10.step(to: maxy, by: 10) do |y|
    draw_horz_line(canvas, (y - miny) * scale, RGBA::LIGHTBLUE)
  end
  -10.step(to: miny, by: -10) do |y|
    draw_horz_line(canvas, (y - miny) * scale, RGBA::LIGHTBLUE)
  end
  50.step(to: maxy, by: 50) do |y|
    draw_horz_line(canvas, (y - miny) * scale, RGBA::LIGHTGREEN)
  end
  -50.step(to: miny, by: -50) do |y|
    draw_horz_line(canvas, (y - miny) * scale, RGBA::LIGHTGREEN)
  end
  if miny <= 0 && 0 <= maxy
    draw_horz_line(canvas, -miny * scale, RGBA::LIGHTPINK)
  end
  10.step(to: maxx, by: 10) do |x|
    draw_vert_line(canvas, (x - minx) * scale, RGBA::LIGHTBLUE)
  end
  -10.step(to: minx, by: -10) do |x|
    draw_vert_line(canvas, (x - minx) * scale, RGBA::LIGHTBLUE)
  end
  50.step(to: maxx, by: 50) do |x|
    draw_vert_line(canvas, (x - minx) * scale, RGBA::LIGHTGREEN)
  end
  -50.step(to: minx, by: -50) do |x|
    draw_vert_line(canvas, (x - minx) * scale, RGBA::LIGHTGREEN)
  end
  if minx <= 0 && 0 <= maxx
    draw_vert_line(canvas, -minx * scale, RGBA::LIGHTPINK)
  end
  StumpyPNG.write(canvas, "picture.png")

  # File.open("picture.txt", "w") do |f|
  #   f.puts "(#{minx},#{miny})-(#{maxx},#{maxy})"
  #   screen = Array.new(maxy - miny + 1) { Array.new(maxx - minx + 1, false) }
  #   pos.each do |p|
  #     screen[p[0] - miny][p[1] - minx] = true
  #   end
  #   top = "     "
  #   x_pos = minx
  #   while top.size < maxx - minx + 7
  #     add = x_pos.to_s
  #     add += " " * (10 - add.size)
  #     top += add
  #     x_pos += 10
  #   end
  #   f.puts top
  #   miny.upto(maxy) do |y|
  #     f.printf("% 4d ", y)
  #     screen[y - miny].each do |pixel|
  #       f.print(pixel ? "#" : " ")
  #     end
  #     f.puts
  #   end
  # end
end

def draw_horz_line(canvas, y, color)
  canvas.width.times do |x|
    canvas[x, y] = color.over(canvas[x, y])
  end
end

def draw_vert_line(canvas, x, color)
  canvas.height.times do |y|
    canvas[x, y] = color.over(canvas[x, y])
  end
end

reducer = Reducer.new
reducer.execute(ARGF)
