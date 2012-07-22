require "chingu"

class Bullet < RemoteGameObject
  traits :velocity, :collision_detection
  trait :bounding_box
  SPEED = 30

  def initialize(options = {})
    super({ image: 'bullet.png', zorder: 150 }.merge(options))
  end

  def angle_rad
    angle / 180 * Math::PI
  end

  module Controls
    attr_reader :damage

    def setup_trait(options = {})
      super
      @weapon = options.fetch(:weapon)
      @x, @y, @angle = @weapon.x, @weapon.y, @weapon.angle

      @damage = options[:damage] || 1
      @penetration = options[:penetration] || 2

      self.velocity_x = SPEED * Math.sin(angle_rad)
      self.velocity_y = - SPEED * Math.cos(angle_rad)

      i = rand(2) + 1
      Gosu::Sound["bullet_#{i}.wav"].play
    end
  end

  # def update
  #   super
  #   each_collision(Zombi) do |bullet, zombi|
  #     @penetration -= 1      
  #     zombi.hit_by(bullet)
  #     destroy && break unless @penetration > 0
  #   end
  # end
end
