class LiveRoom
  # This is a simple value object representing a live room
  # Live rooms are identified by their name string
  
  include ActiveModel::Model
  include ActiveModel::Attributes
  
  attribute :name, :string
  attribute :host_name, :string
  attribute :viewer_count, :integer, default: 0
  
  # Used for polymorphic associations - required by ActiveRecord
  def self.base_class
    self
  end
  
  def self.model_name
    ActiveModel::Name.new(self, nil, "LiveRoom")
  end
  
  def self.primary_key
    'name'
  end
  
  # Generate a unique identifier for follow associations
  def to_param
    name
  end
  
  def id
    name
  end
  
  # Check if a user is following this live room
  def followed_by?(user)
    return false unless user
    Follow.exists?(
      user: user,
      followable_type: "LiveRoom",
      followable_id: name
    )
  end
  
  # Get follower count for this live room
  def followers_count
    Follow.where(followable_type: "LiveRoom", followable_id: name).count
  end
  
  # Required for ActiveRecord association compatibility
  def self.find_by_id(id)
    nil # Live rooms are not persisted
  end
  
  def self.find(id)
    raise ActiveRecord::RecordNotFound
  end
end
