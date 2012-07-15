require "bson"

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
