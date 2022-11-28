# frozen_string_literal: true

module Routes2spec
  # @private
  module Logging
    def debug?
      ENV.fetch("ROUTES2SPEC_DEBUG", nil)
    end

    def log_debug(message)
      warn("[Routes2spec][debug] #{message}") if debug?
    end

    def log(message)
      warn("[Routes2spec] #{message}")
    end

    def warn_deprecated(message)
      warn("[Routes2spec] [DEPRECATION] #{message}")
    end
  end
end
