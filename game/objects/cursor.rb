require "chingu"
require "ostruct"

class Cursor < Chingu::GameObject
  def initialize(options = {})
    super({image: 'cursor.png', zorder: 9000}.merge(options))
  end

  def update
    super
    self.x = $window.mouse_x
    self.y = $window.mouse_y
  end

  module Follower
    attr_accessor :cursor

    def update
      super
      self.angle = Gosu.angle(x, y, cursor.x, cursor.y)
    end
  end
end
