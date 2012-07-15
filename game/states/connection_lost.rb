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
