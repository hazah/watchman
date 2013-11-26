# encoding: utf-8
require 'watchman/hooks'
require 'watchman/config'

module Watchman
  # The middleware for Rack Authorization
  # The middlware requires that there is a user session upstream
  # The middleware injects an authorization guard object into
  # the rack environment hash
  class Manager
    extend Watchman::Hooks
    attr_accessor :config

    # Initialize the middleware. If a block is given, a Watchman::Config is yielded so you can properly
    # configure the Watchman::Manager.
    # :api: public
    def initialize(app, options={})
      default_strategies = options.delete(:default_strategies)

      @app, @config = app, Watchman::Config.new(options)
      @config.default_strategies(*default_strategies) if default_strategies
      yield @config if block_given?
      self
    end

    # Invoke the application guarding for throw :watchman.
    # If this is downstream from another watchman instance, don't do anything.
    # :api: private
    def call(env) # :nodoc:
      return @app.call(env) if env['watchman'] && env['watchman'].manager != self

      #env['watchman'] = Proxy.new(env, self)
      result = catch(:watchman) do
        @app.call(env)
      end

      result ||= {}
      case result
      when Array
        if result.first == 403 && intercept_403?(env)
          process_unauthorized(env)
        else
          result
        end
      when Hash
        process_unauthorized(env, result)
      end
    end


    # :api: private
    def _run_callbacks(*args) #:nodoc:
      self.class._run_callbacks(*args)
    end

    class << self
      # Prepares the permission collection to serialize into the session.
      # Any object that can be serialized into the session in some way can be used as a "persmission collection" object
      # Generally however complex object should not be stored in the session.
      # If possible store only a "key" of the permission object that will allow you to reconstitute it.
      #
      # You can supply different methods of serialization for different scopes by passing a scope symbol
      #
      # Example:
      # Watchman::Manager.serialize_into_session{ |permissions| permissions.to_a.map { |p| p.id } }
      # # With Scope:
      # Watchman::Manager.serialize_into_session(:admin) { |permissions| permissions.to_a.map { |p| p.id } }
      #
      # :api: public
      def serialize_into_session(scope = nil, &block)
        method_name = scope.nil? ? :serialize : "#{scope}_serialize"
        #Watchman::SessionSerializer.send :define_method, method_name, &block
      end

      # Reconstitues the user from the session.
      # Use the results of user_session_key to reconstitue the user from the session on requests after the initial login
      # You can supply different methods of de-serialization for different scopes by passing a scope symbol
      #
      # Example:
      # Watchman::Manager.serialize_from_session{ |ids| Permissions.where(id: ids) }
      # # With Scope:
      # Watchman::Manager.serialize_from_session(:admin) { |ids| AdminUser.get(id) }
      #
      # :api: public
      def serialize_from_session(scope = nil, &block)
        method_name = scope.nil? ? :deserialize : "#{scope}_deserialize"

#        if Watchman::SessionSerializer.method_defined? method_name
#          Watchman::SessionSerializer.send :remove_method, method_name
#        end

#        Watchman::SessionSerializer.send :define_method, method_name, &block
      end
    end

  private

    def intercept_403?(env)
      config[:intercept_403] && !env['watchman'].custom_failure?
    end

    # When a request is unauthorized, here's where the processing occurs.
    # It looks at the result of the proxy to see if it's been executed and what action to take.
    # :api: private
    def process_unauthorized(env, options={})
      options[:action] ||= begin
        opts = config[:scope_defaults][config.default_scope] || {}
        opts[:action] || 'unauthorized'
      end

      proxy = env['watchman']
      result = options[:result] || proxy.result

      case result
      when :redirect
        body = proxy.message || "You are being redirected to #{proxy.headers['Location']}"
        [proxy.status, proxy.headers, [body]]
      when :custom
        proxy.custom_response
      else
        call_failure_app(env, options)
      end
    end

    # Calls the failure app.
    # The before_failure hooks are run on each failure
    # :api: private
    def call_failure_app(env, options={})
      if config.failure_app
        options.merge!(:attempted_path => ::Rack::Request.new(env).fullpath)
        env["PATH_INFO"] = "/#{options[:action]}"
        env["watchman.options"] = options

        _run_callbacks(:before_failure, env, options)
        config.failure_app.call(env).to_a
      else
        raise "No Failure App provided"
      end
    end # call_failure_app
  end
end
