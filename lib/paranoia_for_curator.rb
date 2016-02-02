require 'curator'

module ParanoiaForCurator

  @@default_sentinel_value = nil
  @@default_sentinel_type = Time

  def self.default_sentinel_value=(val)
    @@default_sentinel_value = val
  end

  def self.default_sentinel_value
    @@default_sentinel_value
  end

  def self.default_sentinel_type=(val)
    @@default_sentinel_type = val
  end

  def self.default_sentinel_type
    @@default_sentinel_type
  end

  def self.included(klazz)
    klazz.extend Query
  end

  module Query
    def paranoid? ; true ; end

    def all
      all_with_deleted.find_all{|i| i.send(paranoia_column) == paranoia_sentinel_value }
    end

    def only_deleted
      all_with_deleted.find_all{|i| i.send(paranoia_column) != paranoia_sentinel_value }
    end

    def _find_by_attribute(attribute, value, options = {})
      results = _find_by_attribute_with_deleted(attribute, value)
      without_deleted = options.fetch(:with_deleted) { false }
      results = results.find_all{|i| i.send(paranoia_column) == paranoia_sentinel_value } unless options[:with_deleted]
      results
    end

    def _build_finder_methods(attribute)
      eigenclass = class << self; self; end
      eigenclass.class_eval do
        define_method("find_by_#{attribute}") do |value, options = {}|
          _find_by_attribute(attribute, value, options)
        end
        define_method("find_first_by_#{attribute}") do |value, options = {}|
          _find_by_attribute(attribute, value, options).first
        end
      end
    end

    def find_by_id(id, options = {})
      result = find_by_id_with_deleted(id)
      without_deleted = options.fetch(:with_deleted) { false }
      return nil if result.nil?
      unless options[:with_deleted]
        result = nil unless result.send(paranoia_column) == paranoia_sentinel_value
      end
      result
    end

    def mixin_fields(field, *mixed_fields)
      eigenclass = class << self; self; end
      method_name = "#{field}_#{mixed_fields.join('_')}"
      joined_fields = mixed_fields.map do |x|
        "x.#{x} == #{x} "
      end.join(' && ')

      eigenclass.class_eval do
        eval <<-METHOD
          def find_by_#{method_name}(#{field},#{mixed_fields.join(",")}, sort=true, options = {})
            return [] if #{field}.nil?

            if '#{field}'.to_sym == :id
              result = find_by_id(#{field}, options)
              result = result.nil? ? [] : [result]
            else
              result = _find_by_attribute('#{field}', #{field}, options)
              result.sort! &@sort_with if @sort_with && sort
            end

            result.select do |x|
              #{joined_fields}
            end
          end

          def find_first_by_#{method_name}(#{field},#{mixed_fields.join(",")}, sort=true, options = {})
            find_by_#{method_name}(#{field},#{mixed_fields.join(",")}, sort, options).first
          end
        METHOD
      end
    end

  end
end

module Curator
  module Repository

    def self.included(klazz)
      klazz.extend ClassMethods
    end

    module ClassMethods
      def acts_as_paranoid(options = {})
        eigenclass = class << self; self; end

        eigenclass.class_eval do
          alias_method :really_delete, :delete
          alias_method :all_with_deleted, :all
          alias_method :_find_by_attribute_with_deleted, :_find_by_attribute
          alias_method :find_by_id_with_deleted, :find_by_id
        end

        class_attribute :paranoia_column, :paranoia_sentinel_value, :paranoia_sentinel_type

        self.paranoia_column = (options[:paranoia_column] || :deleted_at).to_s
        self.paranoia_sentinel_value = options.fetch(:sentinel_value) { ParanoiaForCurator.default_sentinel_value }
        self.paranoia_sentinel_type = options.fetch(:sentinel_type) { ParanoiaForCurator.default_sentinel_type }

        include ParanoiaForCurator

        def self.delete(object)
          object.send("#{paranoia_column}=", Time.now)
          self.save(object)
          nil
        end

        def self.paranoid? ; false ; end
        def paranoid? ; self.class.paranoid? ; end

        private

        def paranoia_column
          self.class.paranoia_column
        end

        def paranoia_sentinel_value
          self.class.paranoia_sentinel_value
        end
      end
    end

  end
end
