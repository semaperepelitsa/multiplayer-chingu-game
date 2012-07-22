module Identity
  attr_reader :id

  def self.extended(obj)
    obj.setup_id
  end

  def setup
    super
    setup_id
  end

  def setup_id
    @id = BSON::ObjectId.new
  end

  def id=(id)
    @id = if id.is_a?(BSON::ObjectId)
      id
    else
      BSON::ObjectId.from_string(id["$oid"])
    end
  end
end
