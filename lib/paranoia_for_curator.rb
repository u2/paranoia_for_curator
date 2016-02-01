require 'curator'

module ParanoiaForCurator

  @@default_sentinel_value = nil

  def self.default_sentinel_value=(val)
    @@default_sentinel_value = val
  end

  def self.default_sentinel_value
    @@default_sentinel_value
  end

  def self.included(klazz)
    klazz.extend Query
  end

  module Query
    def paranoid? ; true ; end

    alias_method :all_with_deleted, :all

    def all
      all_with_deleted.paranoia_scope
    end

    def only_deleted
      find_all{|i| i[paranoia_column] != paranoia_sentinel_value }
    end

    alias :deleted :only_deleted

    alias_method :_find_by_attribute_with_deleted, :_find_by_attribute

    def _find_by_attribute(attribute, value, options = {})
      results = _find_by_attribute_with_deleted(attribute, value)
      without_deleted = options.fetch(:without_deleted) { true }
      results.paranoia_scope if options[:without_deleted]
      results
    end
  end
end

module Curator
  module Repository
    def acts_as_paranoid(options = {})
      alias_method :really_delete :delete

      include ParanoiaForCurator

      class_attribute :paranoia_column, :paranoia_sentinel_value

      self.paranoia_column = (options[:paranoia_column] || :deleted_at).to_s
      self.paranoia_sentinel_value = options.fetch(:sentinel_value) { ParanoiaForCurator.default_sentinel_value }

      def self.paranoia_scope
        find_all{|i| i[paranoia_column] == paranoia_sentinel_value }
      end

      def self.delete(object)
        object[paranoia_column] = current_time_from_proper_timezone
        data_store.save(object)
        nil
      end
    end

    def self.paranoid? ; false ; end
    def paranoid? ; self.class.paranoid? ; end

    def current_time_from_proper_timezone
      self.class.default_timezone == :utc ? Time.now.utc : Time.now
    end

    private

    def paranoia_column
      self.class.paranoia_column
    end

    def paranoia_sentinel_value
      self.class.paranoia_sentinel_value
    end
  end
end
