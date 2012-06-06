MockServer = Class.new

class ServerMock
  include Celluloid::IO

  def initialize(host, port)
    puts "*** Starting echo server on #{host}:#{port}"
    @server = TCPServer.new host, port
    run!
  end

  def finalize
    @server.close if @server
  end

  def run
    loop { handle_connection! @server.accept }
  end

  def handle_connection(socket)
    @current_socket = socket
    _, port, host = socket.peeraddr
    puts "*** Received connection from #{host}:#{port}"
    loop { receive_data socket.readpartial(4096) }
  end

  def receive_data(data)
    @mock_server ||= MockServer.new
    @mock_server.receive_data data, self
  end

  def send_data(data)
    @current_socket.write data.gsub("\n", "\r\n")
  end
end

def client
  @client ||= mock('Client')
end
