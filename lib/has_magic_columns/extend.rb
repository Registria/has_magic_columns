require 'active_support'
require 'active_record'
require 'pry-rails'

module HasMagicColumns
  module Extend extend ActiveSupport::Concern
    include ActiveModel::Validations
    module ClassMethods
      def has_magic_columns(options = {})
        unless magical?
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
                self.send(inherited_from) ? self.send(inherited_from).magic_columns : []
              end
            end
            alias_method :magic_columns, :inherited_magic_columns unless method_defined? :magic_columns

          # otherwise the calling model has the relationships
          else
            has_many :magic_column_relationships, :as => :owner, :dependent => :destroy
            has_many :magic_columns, :through => :magic_column_relationships, :dependent => :destroy
          end
        end
        include InstanceMethods
      end

      def magical?
        self.included_modules.include?(InstanceMethods)
      end
    end

    module InstanceMethods
      def update_attributes(new_attributes)
        attributes = new_attributes.stringify_keys
        magic_attrs = magic_columns.map(&:name)

        if super(attributes.select{ |k, v| !magic_attrs.include?(k) })
          attributes.select{ |k, v| magic_attrs.include?(k) }.each do |k, v|
            write_magic_attribute(k, v)
          end
          true
        else
          false
        end
      end

      def magic_column_names
        magic_columns.map(&:name)
      end

      def respond_to_missing?(method_name, include_private = false)
        magic_column_names.map { |attr| "#{attr}=" }.include?(method_name.to_s) || magic_column_names.map { |attr| "#{attr}" }.include?(method_name.to_s) || super
      end

      def write_attribute(attr_name, value)
        if self.attributes.include?(attr_name.to_s)
          super
        else
          method_missing("#{attr_name}=".to_sym, value)
        end
      end

      def read_attribute(attr_name)
        if self.attributes.include?(attr_name.to_s)
          super
        else
          attr_name = attr_name.to_s
          read_attribute_with_magic(attr_name)
        end
      end

      private

      # Load the MagicAttribute(s) associated with attr_name and cast them to proper type.
      def read_attribute_with_magic(attr_name)
        column = find_magic_column_by_name(attr_name)
        attribute = find_magic_attribute_by_column(column)
        if column.datatype.to_s == 'check_box_multiple'
          attribute.map { |attr| column.type_cast(attr.value) }
        else
          value = (attr = attribute.first) ? attr.to_s : column.default
          value.nil?  ? nil : column.type_cast(value)
        end
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
          read_attribute_with_magic(method_name)
        end
      end

      def find_magic_attribute_by_column(column)
        magic_attributes.to_a.find_all do |attr|
         attr.magic_column_id == column.id
        end
      end

      def find_magic_column_by_name(attr_name)
        magic_columns.to_a.find {|column| column.name == attr_name}
      end

      def create_magic_attribute(magic_column, value)
        magic_attributes << MagicAttribute.create(:magic_column => magic_column, :value => value)
      end

      def update_magic_attribute(magic_attribute, value)
        magic_attribute.update_attributes(:value => value)
      end

      def write_magic_attribute(column_name, value)
        column = find_magic_column_by_name(column_name)
        existing = find_magic_attribute_by_column(column)

        if value.is_a?(Array) && column.datatype == "check_box_multiple"
          existing.map(&:destroy) if existing
          value.reject!(&:blank?)
          if value.present?
            value.each do |val|
              create_magic_attribute(column, val)
            end
          end
        else
          if (attr = existing.first)
            value.present? ? update_magic_attribute(attr, value) : attr.destroy
          else
            create_magic_attribute(column, value)
          end
        end
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
