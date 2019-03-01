class MagicColumn < ActiveRecord::Base
  has_many :magic_column_relationships
  has_many :owners, :through => :magic_column_relationships, :as => :owner
  has_many :magic_options
  has_many :magic_attributes, :dependent => :destroy

  validates_presence_of :name, :datatype
  validates_format_of :name, :with => /\A[a-zA-Z0-9_]+\z/

  def type_cast(value)
    begin
      case datatype.to_sym
        when :check_box_boolean
          bool_value(value)
        when :date
          Date.parse(value)
        when :datetime
          Time.parse(value)
        when :integer
          value.to_i
      else
        value
      end
    rescue
      value
    end
  end

  # Display a nicer (possibly user-defined) name for the column or use a fancified default.
  def pretty_name
    super || name.humanize
  end

  private

  def bool_value(value)
    if value.to_s ==  "t" ||  value.to_s ==  "1"
      true
    else
      false
    end
  end
end
