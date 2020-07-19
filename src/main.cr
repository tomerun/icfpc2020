require "big"
require "http/client"
require "./modem.cr"
require "uri"

JOIN     = BigInt.new(2)
START    = BigInt.new(3)
COMMANDS = BigInt.new(4)

class Player
  def initialize(server_url, @player_key : BigInt)
    @uri = URI.parse(server_url + "/aliens/send")
  end

  def play
    begin
      res = join([] of List)
      res = start(bi(1), bi(1), bi(1), bi(1))
      while true
        stage = res[1].as(BigInt)
        break if stage == 2
        commands([] of List)
      end
    rescue e
      puts "Unexpected server response:"
      puts e.inspect_with_backtrace
      exit(1)
    end
  end

  def join(param : List)
    return request([JOIN, @player_key, param])
  end

  def start(x0 : BigInt, x1 : BigInt, x2 : BigInt, x3 : BigInt)
    return request([START, @player_key, [x0, x1, x2, x3]])
  end

  def commands(commands : List)
    return request([COMMANDS, @player_key, commands])
  end

  def request(input : Array(List)) : List
    res = HTTP::Client.post(@uri, body: mod(input))
    if res.status_code == 200
      puts "Server response: %s" % res.body
      puts res.headers
    else
      puts "Unexpected server response:"
      puts "HTTP code: %d" % res.status_code
      puts "Response body: %s" % res.body
      exit(2)
    end
    return get_list(res.body)
  end
end

def bi(i : Int)
  return BigInt.new(i)
end

server_url = ARGV[0]
player_key = BigInt.new(ARGV[1])
player = Player.new(server_url, player_key)
player.play
