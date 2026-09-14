# frozen_string_literal: true

require "ostruct"
require "active_support/core_ext/string/inflections"

module PicqerAPI
  class Base < OpenStruct
    attr_reader :original_response

    def self.new(attributes)
      return attributes.map { |item| super(item) } if attributes.is_a?(Array)

      super
    end

    def initialize(attributes)
      @original_response = deep_freeze(attributes)
      super(to_ostruct(attributes))
    end

    def to_hash
      ostruct_to_hash(self)
    end

    alias_method :to_h, :to_hash

    def raw
      @original_response
    end

    private

    def to_ostruct(object)
      case object
      when Hash
        OpenStruct.new(
          object.transform_keys { |key| key.to_s.underscore }
            .transform_values { |value| to_ostruct(value) }
        )
      when Array
        object.map { |value| to_ostruct(value) }
      else
        object
      end
    end

    def deep_freeze(object)
      case object
      when Hash then object.transform_values { |value| deep_freeze(value) }.freeze
      when Array then object.map { |item| deep_freeze(item) }.freeze
      else object.respond_to?(:freeze) ? object.freeze : object
      end
    end

    def ostruct_to_hash(object)
      case object
      when OpenStruct
        object.each_pair.to_h
          .transform_keys(&:to_s)
          .transform_values { |value| ostruct_to_hash(value) }
      when Array
        object.map { |value| ostruct_to_hash(value) }
      when Hash
        object.transform_keys(&:to_s)
          .transform_values { |value| ostruct_to_hash(value) }
      else
        object
      end
    end
  end
end
