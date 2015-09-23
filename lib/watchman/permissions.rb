# encoding: utf-8
module Watchman
  module Permissions
    class << self
      # Add a permission and store it in a hash.
      def add(label, context = nil, permission = nil, &block)
        permission ||= Class.new(Watchman::Permissions::Base)
        permission.context = context
        permission.class_eval(&block) if block_given?

        base = Watchman::Permissions::Base
        unless permission.ancestors.include?(base)
          raise "#{label.inspect} is not a #{base}"
        end

        _permissions[label] = permission
      end

      # Update a previously given permission.
      def update(label, context = nil, &block)
        permission = _permissions[label]
        raise "Unknown permission #{label.inspect}" unless permission
        add(label, context, permission, &block)
      end

      # Provides access to strategies by label
      # :api: public
      def [](label)
        _permissions[label]
      end

      # Clears all declared.
      # :api: public
      def clear!
        _permissions.clear
      end

      # :api: private
      def _permissions
        @permissions ||= {}
      end
    end # << self
  end # Permissions
end # Watchman
