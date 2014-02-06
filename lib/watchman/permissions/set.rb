# encoding: utf-8
module Watchman
  module Permissions
    class Set < Hash
      # :api: public
      attr_reader :permissions

      # :api: private
      def initialize(permissions, env, scope=nil) # :nodoc:
        @permissions = permissions.inject({}) do |perms, current|
          label = current.name.to_sym
          context = current.context? ? current.context.constantize : nil
          klass = Permissions[label]

          permission = klass.new(env, scope, context)
          perms[label] = permission
          perms
        end
      end

      def [](label)
        permissions[label]
      end
    end
  end
end
