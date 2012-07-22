require "player"
require "cursor"
require "node"
require "connection_lost"

class Play < Chingu::GameState
  def setup
    @player = Player.create(x: rand($window.width), y: rand($window.height))
    @node = Node.create([@player])
    @cursor = Cursor.create
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
