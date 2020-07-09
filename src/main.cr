require "http/client"
require "uri"
require "miller_rabin"

def main
  puts MillerRabin.probably_prime(10459103, 100)

  serverurl = ARGV[0]
  playerkey = ARGV[1]
  puts "ServerUrl: %s; PlayerKey: %s" % [serverurl, playerkey]

  uri = URI.parse(serverurl + "?playerKey=#{playerkey}")
  res = HTTP::Client.get uri
  puts res.status_code
end

main
