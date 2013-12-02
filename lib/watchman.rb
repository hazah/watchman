# encoding: utf-8
require 'forwardable'

require 'watchman/mixins/common'
require 'watchman/proxy'
require 'watchman/manager'
require 'watchman/errors'
require 'watchman/session_serializer'
require 'watchman/strategies'
require 'watchman/strategies/base'
require 'watchman/permissions'

module Watchman
  class NotAuthorized < StandardError; end
end
