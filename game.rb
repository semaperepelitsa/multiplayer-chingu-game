require "chingu"
require "json"
require "bson"
require "logger"

$logger = Logger.new($stdout)
$logger.level = Logger::DEBUG

class Game < Chingu::Window
  def setup
    push_game_state(Play)
  end

  def update
    super
    self.caption = "FPS: #{fps} milliseconds since last tick: #{milliseconds_since_last_tick}, GC: #{GC.count}"
  end
end

class BasicPlayer < Chingu::GameObject
  SPEED = 4
  traits :velocity
  attr_reader :id

  def id=(id)
    @id = if id.is_a?(BSON::ObjectId)
      id
    else
      BSON::ObjectId.from_string(id)
    end
  end

  def initialize(opts={})
    super(opts.merge(image: "player.png", zorder: 100))
    @id = opts.fetch(:id, BSON::ObjectId.new)
  end

  def attributes
    [x, y]
  end

  def attributes=(array)
    self.x = array[0]
    self.y = array[1]
  end
end


class Player < BasicPlayer
  def setup
    self.input = { :holding_a => :move_left,
                   :holding_d => :move_right,
                   :holding_w => :move_up,
                   :holding_s => :move_down }
  end

  def move_left
    move(-SPEED, 0)
  end

  def move_right
    move(SPEED, 0)
  end

  def move_up
    move(0, -SPEED)
  end

  def move_down
    move(0, SPEED)
  end
end

class Node < Chingu::BasicGameObject
  traits :timer
  RECONNECT_AFTER = 500
  SEND_DELAY = 20

  def initialize(controlled)
    super()
    @buffer = ""
    connect
    @controlled = controlled
    @remote = {}
  end

  def update
    super
    
  end

  def connection_lost?
    @socket.nil?
  end

  def connected?
    @socket
  end

  private

  def connect
    return if @socket
    @socket = TCPSocket.open('localhost', 4466)
  rescue Errno::ECONNREFUSED
    $logger.info "Retrying the connection"
    after(RECONNECT_AFTER){ connect }
  else
    $logger.info "Connected"
    every(20, name: :updates) do
      send_updates
      receive_updates
    end
  end

  def connection_lost
    return if connection_lost?
    stop_timer(:updates) # doesn't work?
    @socket = nil
    $logger.info "Connection to the server lost"
    connect
  end

  def connection_totally_lost
    $logger.info "Connection to the server totally lost"
    @remote.each{ |id, object| object.destroy }
    destroy
  end

  def send_updates
    @controlled.each do |object|
      send_data(object)
    end
  end

  def send_data(object)
    @socket.puts JSON.dump([object.id.to_s] << object.attributes) if connected?
  rescue Errno::EPIPE
    connection_lost
  end

  def receive_updates
    @buffer << @socket.read_nonblock(1000) if @socket
  rescue Errno::EAGAIN
  rescue Errno::ECONNRESET, EOFError
    connection_lost
  else
    while message = @buffer.slice!(/.*\n/)
      receive_data(message)
    end
  end

  def receive_data(data)
    id, attributes = JSON.parse(data)
    player = @remote[id] ||= BasicPlayer.create(id: id)
    player.attributes = attributes
  end
end

class ConnectionLost < Chingu::GameState
      
  def initialize(options = {})
    super
    @node = options.fetch(:node)
    add_game_object(@node)
    @white = Gosu::Color.new(255,255,255,255)
    @color = Gosu::Color.new(200,0,0,0)
    @font = Gosu::Font[35]
    @text = "Connection lost. Retrying..."
  end

  def update
    super
    pop_game_state(:setup => false) if @node.connected?
  end

  def draw
    previous_game_state.draw    # Draw prev game state onto screen (in this case our level)
    $window.draw_quad(  0,0,@color,
                        $window.width,0,@color,
                        $window.width,$window.height,@color,
                        0,$window.height,@color, Chingu::DEBUG_ZORDER)
                            
    @font.draw(@text, ($window.width/2 - @font.text_width(@text)/2), $window.height/2 - @font.height, Chingu::DEBUG_ZORDER + 1)
  end  
end

class Play < Chingu::GameState
  def setup
    @player = Player.create(x: rand($window.width), y: rand($window.height))
    @node = Node.create([@player])
  end

  def draw
    Gosu::Image["grass.png"].draw(0, 0, 0)
    super
  end

  def update
    super
    push_game_state(ConnectionLost.new(node: @node)) if @node.connection_lost?
  end
end

Game.new(800, 600, false).show
