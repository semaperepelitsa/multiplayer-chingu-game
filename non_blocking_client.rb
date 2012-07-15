require 'socket'      # Sockets are in standard library

s = TCPSocket.open('localhost', 4467)
buffer = ""

loop do
  print "-\r"
  begin
    message = s.read_nonblock(1000)
  rescue Errno::EAGAIN
  rescue EOFError
    break
  else
    buffer << message
    while message = buffer.slice!(/.*\n/)
      p message
    end
  end
  print "|\r"
  # break if message.nil?
end

puts "Connection closed"
