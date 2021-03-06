require "bson"
require "handgun"
require "identity"
require "cursor"

class Player < RemoteGameObject
  SPEED = 4
  traits :velocity

  def initialize(opts={})
    super(opts.merge(image: "player.png", zorder: 100))
  end

  module Controls
    attr_accessor :weapon

    def self.extended(obj)
      obj.extend(Cursor::Follower)
    end

    def setup
      super
      @weapon = Handgun.create(player: self)
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
end
