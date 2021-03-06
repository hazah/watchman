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

      # :api: private
      def ensure!(subject)
        throw(:watchman, scope: scope, context: context, subject: subject) unless subject.nil? ?
                                                                        context.nil? :
                                                                        permitted?(subject)
      end

      def permitted(subject)
        return nil if subject.nil?
        if _collection?(subject)
          @collection_result
        elsif subject.respond_to?(_select_method)
          subject.send(_select_method, &resource)
        else
          nil
        end
      end

      def permitted?(subject)
        subject.nil? || if _collection?(subject)
          @collection_result.send(_length_method) > 0
        elsif subject.respond_to?(_select_method)
          subject.send(_select_method, &resource).length > 0
        else
          resource.call(subject)
        end
      end

      class << self
        def collection &block
          define_method :collection do
            @collection ||= block
          end
        end

        def resource &block
          define_method :resource do
            @resource ||= block
          end
        end

        attr_accessor :context

        def permitted? permission, subject=nil
        end
      end

    private
      def _collection?(subject)
        @collection_result = collection.call(subject) rescue false
        @collection_result != false
      end

      def _length_method # :api: private
        :length
      end

      def _select_method # :api: private
        :select
      end
    end
  end
end
