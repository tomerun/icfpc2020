require "http/client"
require "uri"

def main
  begin
    serverurl = ARGV[0]
    playerkey = ARGV[1]
    puts "ServerUrl: %s; PlayerKey: %s" % [serverurl, playerkey]

    uri = URI.parse(serverurl + "/aliens/send?apiKey=#{playerkey}")
    res = HTTP::Client.post(uri, body: playerkey)
    if res.status_code == 200
      puts "Server response: %s" % res.body
    else
      puts "Unexpected server response:"
      puts "HTTP code: %d" % res.status_code
      puts "Response body: %s" % res.body
      exit(2)
    end
  rescue e
    puts "Unexpected server response:"
    puts e.inspect_with_backtrace
    exit(1)
  end
end

main
