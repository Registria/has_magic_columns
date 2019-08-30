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
          has_many :magic_attribute_relationships, as: :owner, dependent: :destroy
          has_many :magic_attributes, through: :magic_attribute_relationships, dependent: :destroy

          if options[:through].present?
            delegate :magic_columns, to: options[:through], allow_nil: true
          else
            has_many :magic_column_relationships, as: :owner, dependent: :destroy
            has_many :magic_columns, through: :magic_column_relationships, dependent: :destroy
          end
        end
        include InstanceMethods
      end

      def magical?
        self.included_modules.include?(InstanceMethods)
      end
    end

    module InstanceMethods
      def magic_column_names
        (magic_columns || []).map(&:name)
      end

      def magic_changes
        @magic_changes ||= {}
      end

      def magic_changed?
        magic_changes.present?
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

      def reload
        @magic_changes = {}
        super
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
          value.nil? ? nil : column.type_cast(value)
        end
      end

      def method_missing(method_id, *args)
        super(method_id, *args)
      rescue NameError
        method_name = method_id.to_s
        super(method_id, *args) unless magic_column_names.include?(method_name) or (md = /[\?|\=]/.match(method_name) and magic_column_names.include?(md.pre_match))
        if method_name =~ /=$/
          var_name = method_name.gsub('=', '')
          value = args.first
          write_magic_attribute(var_name, value)
        else
          read_attribute_with_magic(method_name)
        end
      end

      def find_magic_attribute_by_column(column)
        magic_attributes.to_a.find_all { |attr| attr.magic_column_id == column.id }
      end

      def find_magic_column_by_name(attr_name)
        magic_columns.to_a.find { |column| column.name == attr_name }
      end

      def create_magic_attributes(magic_column, existing, values)
        return if existing.map(&:value).sort == values.sort
        existing.map(&:destroy) if existing.present?
        values.each do |value|
          magic_attributes << MagicAttribute.create(magic_column: magic_column, value: value)
        end
        magic_changes[magic_column.name] = [nil, values]
        self.touch if self.persisted?
      end

      def destroy_magic_attributes(magic_column, existing)
        return if existing.blank?
        existing.map(&:destroy)
        magic_changes[magic_column.name] = [existing.map(&:value), nil]
        self.touch if self.persisted?
      end

      def create_magic_attribute(magic_column, value)
        return if value.to_s.blank?
        magic_changes[magic_column.name] = [nil, value]
        magic_attributes << MagicAttribute.create(magic_column: magic_column, value: value)
        self.touch if self.persisted?
      end

      def update_magic_attribute(magic_attribute, value)
        return if magic_attribute.value == value
        magic_changes[magic_attribute.magic_column.name] = [magic_attribute.value, value]
        magic_attribute.update_attributes(value: value)
        self.touch if self.persisted? && magic_attribute.updated_at > self.updated_at
      end

      def destroy_magic_attribute(magic_attribute)
        magic_changes[magic_attribute.magic_column.name] = [magic_attribute.value, nil]
        magic_attribute.destroy
        self.touch if self.persisted?
      end

      def write_magic_attribute(column_name, value)
        column = find_magic_column_by_name(column_name)
        existing = find_magic_attribute_by_column(column)

        if value.is_a?(Array) && column.datatype == "check_box_multiple"
          value.reject!(&:blank?)
          value.present? ? create_magic_attributes(column, existing, value) : destroy_magic_attributes(column, existing)
        else
          value = value.first if value.is_a?(Array)

          if (attr = existing.first)
            value.to_s.present? ? update_magic_attribute(attr, value) : destroy_magic_attribute(attr)
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
