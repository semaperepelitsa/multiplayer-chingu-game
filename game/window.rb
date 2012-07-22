require "chingu"
require "logger"

class Chingu::GameObject
  def remote?
    false
  end
end

class RemoteGameObject < Chingu::GameObject
  module Controls
  end

  def attributes
    [x, y, angle, self.class.name]
  end

  def attributes=(array)
    self.x, self.y, self.angle = array
  end

  def initialize(options = {})
    extend(self.class::Controls) unless options[:remote]
    super
  end

  def remote?
    not kind_of?(self.class::Controls)
  end
end

require "play"

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
