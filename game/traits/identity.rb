module Identity
  attr_reader :id

  def self.extended(obj)
    obj.setup
  end

  def setup
    super
    @id = BSON::ObjectId.new
  end

  def id=(id)
    @id = if id.is_a?(BSON::ObjectId)
      id
    else
      BSON::ObjectId.from_string(id)
    end
  end
end
