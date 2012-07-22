require "chingu"
require "logger"
require "play"

class Chingu::GameObject
  def attributes
    [x, y]
  end

  def attributes=(array)
    self.x = array[0]
    self.y = array[1]
  end
end

class Game < Chingu::Window
  def setup
    $logger = Logger.new($stdout)
    $logger.level = Logger::DEBUG
    push_game_state(Play)
  end

  def update
    super
    self.caption = "FPS: #{fps} milliseconds since last tick: #{milliseconds_since_last_tick}, GC: #{GC.count}"
  end
end
