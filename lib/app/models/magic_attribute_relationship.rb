class MagicAttributeRelationship < ActiveRecord::Base
  belongs_to :magic_attribute
  belongs_to :owner, :polymorphic => true

  self.primary_key = "id"
end
