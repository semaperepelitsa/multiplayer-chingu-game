require "player"
require "cursor"
require "node"
require "connection_lost"

class Play < Chingu::GameState
  def setup
    @player = Player.create(x: rand($window.width), y: rand($window.height))
    @cursor = Cursor.create
    @player.cursor = @cursor
    @node = Node.create([@player, @player.weapon])
    p @player.remote?
  end

  def add_game_object(obj)
    super
    @node.controlled << obj if defined?(@node) and not obj.remote?
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
