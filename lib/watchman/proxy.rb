# encoding: utf-8

module Watchman
  class UserNotSet < RuntimeError; end

  class Proxy
    # An accessor to the winning strategy
    # :api: private
    attr_accessor :winning_strategy

    # An accessor to the rack env hash, the proxy owner and its config
    # :api: public
    attr_reader :env, :manager, :config, :winning_strategies


    include ::Watchman::Mixins::Common
  end
end
