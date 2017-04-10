# Always work through the interface MagicAttribute.value
class MagicAttribute < ActiveRecord::Base
  belongs_to :magic_column

  def to_s
    value
  end

end
