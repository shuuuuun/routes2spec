# frozen_string_literal: true

require_relative "routes2spec/version"
require_relative "routes2spec/logging"
# require_relative "routes2spec/railtie"
# require_relative "rails/commands/routes/routes2spec_command"
require_relative "routes2spec/routes2spec_command"

module Routes2spec
  class Error < StandardError; end

  class << self
    include Routes2spec::Logging
  end
end
