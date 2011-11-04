MockServer = Class.new

module ServerMock
  def receive_data(data)
    @server ||= MockServer.new
    @server.receive_data data, self
  end

  def send_data(data)
    super data.gsub("\n", "\r\n")
  end
end

def client
  @client ||= mock('Client')
end
