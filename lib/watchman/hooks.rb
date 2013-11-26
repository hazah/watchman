# encoding: utf-8
module Watchman
  module Hooks

    # Hook to _run_callbacks asserting for conditions.
    def _run_callbacks(kind, *args) #:nodoc:
      options = args.last # Last callback arg MUST be a Hash

      send("_#{kind}").each do |callback, conditions|
        invalid = conditions.find do |key, value|
          value.is_a?(Array) ? !value.include?(options[key]) : (value != options[key])
        end

        callback.call(*args) unless invalid
      end
    end

    # A callback hook set to run every time after permissions are set.
    # This callback is triggered the first time one of those three events happens
    # during a request: :authorization, :fetch (from session) and :set_permissions (when manually set).
    # You can supply as many hooks as you like, and they will be run in order of declaration.
    #
    # If you want to run the callbacks for a given scope and/or event, you can specify them as options.
    # See parameters and example below.
    #
    # Parameters:
    # <options> Some options which specify when the callback should be executed
    #   scope - Executes the callback only if it maches the scope(s) given
    #   only - Executes the callback only if it matches the event(s) given
    #   except - Executes the callback except if it matches the event(s) given
    # <block> A block where you can set arbitrary logic to run every time permissions are set
    #   Block Parameters: |permissions, auth, opts|
    #     permissions - The permissions collection object that is being set
    #     auth - The raw authorization proxy object.
    #     opts - any options passed into the set_permissions call includeing :scope
    #
    # Example:
    # Watchman::Manager.after_set_permissions do |permissions,auth,opts|
    #   scope = opts[:scope]
    #   if auth.session["#{scope}.last_access"].to_i > (Time.now - 5.minutes)
    #     auth.logout(scope)
    #     throw(:watchman, :scope => scope, :reason => "Times Up")
    #   end
    #   auth.session["#{scope}.last_access"] = Time.now
    # end
    #
    # Watchman::Manager.after_set_permissions :except => :fetch do |permissions,auth,opts|
    #   permissions << Permission.new(:read_published, Post, published: true)
    # end
    #
    # :api: public
    def after_set_permissions(options = {}, method = :push, &block)
      raise BlockNotGiven unless block_given?

      if options.key?(:only)
        options[:event] = options.delete(:only)
      elsif options.key?(:except)
        options[:event] = [:set_permissions, :authorization, :fetch] - Array(options.delete(:except))
      end

      _after_set_permissions.send(method, [block, options])
    end

    # Provides access to the array of after_set_user blocks to run
    # :api: private
    def _after_set_permissions # :nodoc:
      @_after_set_permissions ||= []
    end

    # after_authorization is just a wrapper to after_set_permissions, which is only invoked
    # when the permissions are set through the authorization path. The options and yielded arguments
    # are the same as in after_set_user.
    #
    # :api: public
    def after_authorization(options = {}, method = :push, &block)
      after_set_permissions(options.merge(:event => :authorization), method, &block)
    end

    # after_fetch is just a wrapper to after_set_permissions, which is only invoked
    # when the permissions are fetched from sesion. The options and yielded arguments
    # are the same as in after_set_permissions.
    #
    # :api: public
    def after_fetch(options = {}, method = :push, &block)
      after_set_permissions(options.merge(:event => :fetch), method, &block)
    end

    # A callback that runs just prior to the failur application being called.
    # This callback occurs after PATH_INFO has been modified for the failure (default /unauthorized)
    # In this callback you can mutate the environment as required by the failure application
    # If a Rails controller were used for the failure_app for example, you would need to set request[:params][:action] = :unauthenticated
    #
    # Parameters:
    # <options> Some options which specify when the callback should be executed
    # scope - Executes the callback only if it maches the scope(s) given
    # <block> A block to contain logic for the callback
    # Block Parameters: |env, opts|
    # env - The rack env hash
    # opts - any options passed into the authenticate call includeing :scope
    #
    # Example:
    # Watchman::Manager.before_failure do |env, opts|
    #   params = Rack::Request.new(env).params
    #   params[:action] = :unauthorized
    #   params[:watchman_failure] = opts
    # end
    #
    # :api: public
    def before_failure(options = {}, method = :push, &block)
      raise BlockNotGiven unless block_given?
      _before_failure.send(method, [block, options])
    end

    # Provides access to the callback array for before_failure
    # :api: private
    def _before_failure
      @_before_failure ||= []
    end

    # A callback that runs if no permissions could be fetched, meaning there are now no permitted actions.
    #
    # Parameters:
    # <options> Some options which specify when the callback should be executed
    #   scope - Executes the callback only if it maches the scope(s) given
    # <block> A block to contain logic for the callback
    #   Block Parameters: |permissions, auth, scope|
    #     permissions - The authenticated user's permissions for the current scope
    #     auth - The watchman proxy object
    #     opts - any options passed into the authorize call including :scope
    #
    # Example:
    # Watchman::Manager.after_failed_fetch do |permissions, auth, opts|
    #   I18n.locale = :en
    # end
    #
    # :api: public
    def after_failed_fetch(options = {}, method = :push, &block)
      raise BlockNotGiven unless block_given?
      _after_failed_fetch.send(method, [block, options])
    end

    # Provides access to the callback array for after_failed_fetch
    # :api: private
    def _after_failed_fetch
      @_after_failed_fetch ||= []
    end

    # A callback that runs on each request, just after the proxy is initialized
    #
    # Parameters:
    # <block> A block to contain logic for the callback
    #   Block Parameters: |proxy|
    #     proxy - The watchman proxy object for the request
    #
    # Example:
    #   permissions = [:read, :update]
    #   Watchman::Manager.on_request do |proxy|
    #     proxy.set_permissions = permissions
    #   end
    #
    # :api: public
    def on_request(options = {}, method = :push, &block)
      raise BlockNotGiven unless block_given?
      _on_request.send(method, [block, options])
    end

    # Provides access to the callback array for on_request
    # :api: private
    def _on_request
      @_on_request ||= []
    end

    # Add prepend filters version
    %w(after_set_permissions after_authorization after_fetch on_request
       before_failure).each do |filter|
      class_eval <<-METHOD, __FILE__, __LINE__ + 1
        def prepend_#{filter}(options={}, &block)
          #{filter}(options, :unshift, &block)
        end
      METHOD
    end
  end
end
