# frozen_string_literal: true

require_relative "routes2spec/version"
require_relative "routes2spec/logging"
require_relative "routes2spec/railtie"

module Routes2spec
  class Error < StandardError; end

  class << self
    include Routes2spec::Logging
  end
end
