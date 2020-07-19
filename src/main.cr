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
      res = start(bi(1), bi(1), bi(1), bi(1))
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
            v = [] of List
            v << bi(s.pos[0]) << bi(s.pos[1])
            puts "accel: #{dx} #{dy} #{s.id}"
            cmd = [] of List
            cmd << CMD_ACC << s.id << v << [] of List
            cs << cmd
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
          v = [] of List
          v << bi(-mx) << bi(-my)
          puts "accel: #{mx} #{my} #{s.id}"
          cmd = [] of List
          cmd << CMD_ACC << s.id << v << [] of List
          cs << cmd
        end
        if !cs.empty?
          cs << [] of List
        end
        commands(cs)
      end
    rescue e
      puts "Unexpected server response:"
      puts e.inspect_with_backtrace
      exit(1)
    end
  end

  def join(param : List)
    return request([JOIN, @player_key, param, [] of List])
  end

  def start(x0 : BigInt, x1 : BigInt, x2 : BigInt, x3 : BigInt)
    return request([START, @player_key, [x0, x1, x2, x3, [] of List], [] of List])
  end

  def commands(commands : List)
    return request([COMMANDS, @player_key, commands, [] of List])
  end

  def request(input : Array(List)) : List
    body = mod(input)
    puts "req: #{body}"
    res = HTTP::Client.post(@uri, body: body)
    if res.status_code == 200
      ret = get_list(res.body)
      puts "Server response: #{ret}"
      puts "#{res.body}"
      assert(ret[0] == 1)
      if ret[1] == 2
        exit(0)
      end
      return ret
    else
      puts "Unexpected server response:"
      puts "HTTP code: %d" % res.status_code
      puts "Response body: %s" % res.body
      exit(2)
    end
  end
end

def bi(i : Int)
  return BigInt.new(i)
end

server_url = ARGV[0]
player_key = BigInt.new(ARGV[1])
player = Player.new(server_url, player_key)
player.play
