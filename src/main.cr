require "big"
require "http/client"
require "./modem.cr"
require "uri"

JOIN        = BigInt.new(2)
START       = BigInt.new(3)
COMMANDS    = BigInt.new(4)
ROLE_ATTACK = BigInt.new(0)
CMD_ACC     = BigInt.new(0)
DET_ACC     = BigInt.new(1)
SHT_ACC     = BigInt.new(2)

alias PI = Tuple(Int32, Int32)

class Ship
  getter :id, :position, :pos, :vel

  def initialize(@id : BigInt, @pos : PI, @vel : PI,
                 @x4 : List, @x5 : List, @x6 : List, @x7 : List)
  end
end

def to_pi(v : List) : PI
  l = v.as(Array(List))
  return {l[0].as(BigInt).to_i, l[1].as(BigInt).to_i}
end

class Player
  def initialize(server_url, @player_key : BigInt)
    @uri = URI.parse(server_url + "/aliens/send")
    @is_attack = false
    @my_ships = [] of Ship
    @enemy_ships = [] of Ship
    @static_info = [] of List
  end

  def set_ships(game_state : List)
    @my_ships.clear
    @enemy_ships.clear
    scs = game_state.as(Array(List))[2].as(Array(List))
    scs.each do |sc|
      ship_info = sc.as(Array(List))[0].as(Array(List))
      role = ship_info[0]
      ship_id = ship_info[1].as(BigInt)
      pos = to_pi(ship_info[2])
      vel = to_pi(ship_info[3])
      ship = Ship.new(ship_id, pos, vel, ship_info[4], ship_info[5], ship_info[6], ship_info[7])
      if (role == ROLE_ATTACK) == @is_attack
        @my_ships << ship
      else
        @enemy_ships << ship
      end
    end
    puts "my_ships: #{@my_ships}"
    puts "enemy_ships: #{@enemy_ships}"
  end

  def play
    begin
      res = join([] of List)
      @is_attack = res[2].as(Array(List))[1] == ROLE_ATTACK
      max_cost = @static_info[2].as(Array(List))[0].as(BigInt).to_i
      if @is_attack
        x1 = 0
        x2 = 8
        x3 = 1
      else
        x1 = 0
        x2 = 12
        x3 = 1
      end
      x0 = max_cost - x1 * 4 - x2 * 12 - x3 * 2
      puts "params:#{[x0, x1, x2, x3]}"
      res = start(bi(x0), bi(x1), bi(x2), bi(x3))
      set_ships(res[3])
      while true
        stage = res[1].as(BigInt)
        break if stage == 2
        cs = [] of List
        @my_ships.each do |s|
          vx = s.vel[0]
          vy = s.vel[1]
          dx = -s.pos[0]
          dy = -s.pos[1]
          puts "#{vx} #{vy} #{dx} #{dy}"
          next if vx == 0 && vy == 0
          if (s.pos[0] + vx).abs <= 16 && (s.pos[1] + vy).abs <= 16 ||
             (s.pos[0] + vx * 2).abs <= 16 && (s.pos[1] + vy * 2).abs <= 16
            cs << create_acc(s.id, s.pos[0], s.pos[1])
            next
          end
          cos = (dx * vx + dy * vy) / (((dx ** 2 + dy ** 2)**0.5) * ((vx ** 2 + vy ** 2) ** 0.5))
          puts "cos : #{cos}"
          next if cos < 0.2
          if vx * dy - vy * dx < 0
            mx = -vy
            my = vx
          else
            mx = vy
            my = -vx
          end
          cs << create_acc(s.id, mx, my)
        end
        if !cs.empty?
          cs << [] of List
        end
        res = commands(cs)
        set_ships(res[3])
      end
    rescue e
      puts "Unexpected server response:"
      puts e.inspect_with_backtrace
      exit(1)
    end
  end

  def join(param : List)
    res = request([JOIN, @player_key, param, [] of List])
    @static_info = res[2].as(Array(List))
    puts "static_info:#{res[2]}"
    return res
  end

  def start(x0 : BigInt, x1 : BigInt, x2 : BigInt, x3 : BigInt)
    res = request([START, @player_key, [x0, x1, x2, x3, [] of List], [] of List])
    print_game_state(res[3])
    return res
  end

  def commands(commands : List)
    res = request([COMMANDS, @player_key, commands, [] of List])
    print_game_state(res[3])
    return res
  end

  def print_game_state(game_state)
    gl = game_state.as(Array(List))
    puts "tick:#{gl[0]}"
    puts "size?:#{gl[1]}"
    gl[2].as(Array(List)).each do |s|
      puts s
    end
  end

  def create_acc(ship_id, mx, my)
    v = [] of List
    dir = ([[0, 1], [1, 1], [1, 0], [1, -1], [0, -1], [-1, -1], [-1, 0], [-1, 1]].max_by do |d|
      x = d[0]
      y = d[1]
      (mx * x + my * y) / ((x * x + y * y) ** 0.5)
    end)
    v << bi(-dir[0]) << bi(-dir[1])
    puts "accel: (#{mx} #{my}) (#{dir[0]} #{dir[1]}) #{ship_id}"
    cmd = [] of List
    cmd << CMD_ACC << ship_id << v << [] of List
  end

  def request(input : Array(List)) : List
    body = mod(input)
    # puts "req: #{body}"
    res = HTTP::Client.post(@uri, body: body)
    if res.status_code == 200
      ret = get_list(res.body)
      # puts "Server response: #{ret}"
      assert(ret[0] == 1)
      puts "stage:#{ret[1]}"
      if ret[1] == 2
        exit(0)
      end
      return ret
    else
      puts "Unexpected server response:"
      puts "HTTP code: %d" % res.status_code
      puts "Response body: %s" % res.body
      puts "#{get_list(res.body)}"
      exit(2)
    end
  end
end

def bi(i : Int)
  return BigInt.new(i)
end

server_url = ARGV[0]
player_key = BigInt.new(ARGV[1])
puts "server_url:#{server_url}"
player = Player.new(server_url, player_key)
player.play
