require 'socket'      # Sockets are in standard library

s = TCPSocket.open('localhost', 4466)

threads = []

write = Thread.start do
  loop do
    break if s.closed?
    begin
      s.puts "Hello #{Process.pid} #{Time.now}"
    rescue Errno::EPIPE
      break
    end
    sleep 1
  end
end

read = Thread.start do
  loop do
    message = s.gets
    break if message.nil?
    puts "Received: #{message}"
  end
end

[read, write].each(&:join)
puts "Connection closed"
