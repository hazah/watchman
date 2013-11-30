# encoding: utf-8
require 'forwardable'

require 'watchman/mixins/common'
require 'watchman/proxy'
require 'watchman/manager'

module Watchman
  class NotAuthorized < StandardError; end
end
