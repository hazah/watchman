# encoding: utf-8
module Watchman
  module Permissions
    class Base
      # :api: public
      attr_reader :env, :scope, :context

      include ::Watchman::Mixins::Common
      # :api: private
      def initialize(env, scope=nil, context=nil) # :nodoc:
        @env, @scope, @context = env, scope, context
      end
    end
  end
end
