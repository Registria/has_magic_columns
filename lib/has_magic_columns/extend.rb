require 'active_support'
require 'active_record'

module HasMagicColumns
  module Extend extend ActiveSupport::Concern
    include ActiveModel::Validations
    module ClassMethods
      def has_magic_columns(options = {})
        # Associations
        has_many :magic_attribute_relationships, :as => :owner, :dependent => :destroy
        has_many :magic_attributes, :through => :magic_attribute_relationships, :dependent => :destroy

        # Inheritence
        cattr_accessor :inherited_from


        # if options[:through] is supplied, treat as an inherited relationship
        if self.inherited_from = options[:through]
          class_eval do
            def inherited_magic_columns
              raise "Cannot inherit MagicColumns from a non-existant association: #{@inherited_from}" unless self.class.method_defined?(inherited_from)# and self.send(inherited_from)
              self.send(inherited_from).magic_columns
            end
          end
          alias_method :magic_columns, :inherited_magic_columns unless method_defined? :magic_columns

        # otherwise the calling model has the relationships
        else
          has_many :magic_column_relationships, :as => :owner, :dependent => :destroy
          has_many :magic_columns, :through => :magic_column_relationships, :dependent => :destroy
          # alias_method_chain :magic_columns, :scoped
        end
        alias_method  :magic_columns_without_scoped, :magic_columns
      end

    end

    included do

      def create_magic_column(options = {})
        type_scoped = options[:type_scoped].blank? ? self.class.name : options[:type_scoped].classify
        self.magic_columns.create options.merge(type_scoped: type_scoped )
      end

      def magic_columns_with_scoped(type_scoped = nil)
        type_scoped = type_scoped.blank? ? self.class.name : type_scoped.classify
        magic_columns_without_scoped.where(type_scoped: type_scoped)
      end

      def method_missing(method_id, *args)
        super(method_id, *args)
      rescue NoMethodError
        method_name = method_id.to_s
        super(method_id, *args) unless magic_column_names.include?(method_name) or (md = /[\?|\=]/.match(method_name) and magic_column_names.include?(md.pre_match))

        if method_name =~ /=$/
          var_name = method_name.gsub('=', '')
          value = args.first
          write_magic_attribute(var_name,value)
        else
          read_magic_attribute(method_name)
        end
      end

      def magic_column_names(type_scoped = nil)
        magic_columns_with_scoped(type_scoped).map(&:name)
      end

      def valid?(context = nil)
        output = super(context)
        magic_columns_with_scoped.each do |columns|
          if column.is_required?
            validates_presence_of(column.name)
          end
        end
        errors.empty? && output
      end

      # Load the MagicAttribute(s) associated with attr_name and cast them to proper type.
      def read_magic_attribute(column_name)
        column = find_magic_column_by_name(column_name)
        attribute = find_magic_attribute_by_column(column)
        value = (attr = attribute.first) ?  attr.to_s : column.default
        value.nil?  ? nil : column.type_cast(value)
      end

      def write_magic_attribute(column_name, value)
        column = find_magic_column_by_name(column_name)
        attribute = find_magic_attribute_by_column(column)
        (attr = attribute.first) ? update_magic_attribute(attr, value) : create_magic_attribute(column, value)
      end

      def find_magic_attribute_by_column(column)
        magic_attributes.to_a.find_all {|attr| attr.magic_column_id == column.id}
      end

      def find_magic_column_by_name(attr_name)
        magic_columns_with_scoped.to_a.find {|column| column.name == attr_name}
      end

      def create_magic_attribute(magic_column, value)
        magic_attributes << MagicAttribute.create(:magic_column => magic_column, :value => value)
      end

      def update_magic_attribute(magic_attribute, value)
        magic_attribute.update_attributes(:value => value)
      end
    end


    %w{ models }.each do |dir|
      path = File.join(File.dirname(__FILE__), '../app', dir)
      $LOAD_PATH << path
      ActiveSupport::Dependencies.autoload_paths << path
      ActiveSupport::Dependencies.autoload_once_paths.delete(path)
    end

  end
end
