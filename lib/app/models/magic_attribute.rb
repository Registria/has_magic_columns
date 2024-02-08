# Always work through the interface MagicAttribute.value
class MagicAttribute < ActiveRecord::Base
  belongs_to :magic_column

  self.primary_key = "id"

  def to_s
    value
  end
end
