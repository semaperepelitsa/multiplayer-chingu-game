require "chingu"
require "json"
require "bson"
require "logger"

$logger = Logger.new($stdout)
$logger.level = Logger::INFO

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

  def self.load(attributes)
    player = all.find{ |p| p.id.to_s == attributes.first }
    player ||= create
    player.attributes = attributes
  end

  def id=(id)
    @id = if id.is_a?(BSON::ObjectId)
      id
    else
      BSON::ObjectId.from_string(id)
    end
  end

  def initialize(opts={})
    super(opts.merge(image: "player.png", zorder: 100))
    @id = BSON::ObjectId.new
  end

  def attributes
    [id.to_s].concat(super)
  end

  def attributes=(array)
    self.id = array.shift
    self.x = array[0]
    self.y = array[1]
    # super
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
  DELAY = 20

  def initialize(controlled)
    super()
    @buffer = ""
    @socket = TCPSocket.open('localhost', 4466)
    @controlled = controlled
    every(DELAY) { send_data }
  end

  def update
    super
    receive_updates
  end

  def destroy
    super
    @socket.close
  end

  private

  def send_data
    @controlled.each do |object|
      @socket.puts JSON.dump(object.attributes)
    end
  end

  def receive_updates
    @buffer << @socket.read_nonblock(1000)
  rescue Errno::EAGAIN
  else
    while message = @buffer.slice!(/.*\n/)
      receive_data(message)
    end
  end

  def receive_data(data)
    BasicPlayer.load(JSON.parse(data))
  end
end

class Play < Chingu::GameState
  def setup
    @player = Player.create(x: rand($window.width), y: rand($window.height))
    # @remote = RemotePlayer.create
    Node.create([@player])
  end

  def draw
    Gosu::Image["grass.png"].draw(0, 0, 0)
    super
  end
end

Game.new(800, 600, false).show
