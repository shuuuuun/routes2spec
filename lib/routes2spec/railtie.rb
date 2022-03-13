# frozen_string_literal: true

module Routes2spec
  class Railtie < Rails::Railtie
    rake_tasks do
      load "routes2spec/routes2spec.rake"
    end
  end
end
