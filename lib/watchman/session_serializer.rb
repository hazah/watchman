# encoding: utf-8
module Watchman
  class SessionSerializer
    attr_reader :env

    def initialize(env)
      @env = env
    end

    def key_for(scope)
      "watchman.permissions.#{scope}.key"
    end

    def serialize(permissions)
      permissions
    end

    def deserialize(key)
      key
    end

    def store(set, scope)
      return unless set
      permissions = set.permissions_for_session
      method_name = "#{scope}_serialize"
      specialized = respond_to?(method_name)
      session[key_for(scope)] = specialized ? send(method_name, permissions) : serialize(permissions)
    end

    def fetch(scope)
      key = session[key_for(scope)]
      return nil unless key

      method_name = "#{scope}_deserialize"
      permissions = respond_to?(method_name) ? send(method_name, key) : deserialize(key)
      delete(scope) unless permissions
      ::Watchman::Permissions::Set.new(permissions, env, scope)
    end

    def stored?(scope)
      !!session[key_for(scope)]
    end

    def delete(scope, permissions=nil)
      session.delete(key_for(scope))
    end

    # We can't cache this result because the session can be lazy loaded
    def session
      env["rack.session"] || {}
    end
  end # SessionSerializer
end # Watchman
