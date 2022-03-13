# frozen_string_literal: true

# https://github.com/rails/rails/blob/5-2-stable/railties/lib/rails/tasks/routes.rake

require "optparse"
require "thor"
require_relative "./request_spec_formatter"

namespace :routes do
  desc "Generate request specs for all defined routes in match order, with names. Target specific controller with -c option, or grep routes using -g option"
  task request_spec: :environment do
    all_routes = Rails.application.routes.routes
    require "action_dispatch/routing/inspector"
    inspector = ActionDispatch::Routing::RoutesInspector.new(all_routes)

    routes_filter = nil

    OptionParser.new do |opts|
      opts.banner = "Usage: rails routes:request_spec [options]"

      Rake.application.standard_rake_options.each { |args| opts.on(*args) }

      opts.on("-c CONTROLLER") do |controller|
        routes_filter = { controller: controller }
      end

      opts.on("-g PATTERN") do |pattern|
        routes_filter = pattern
      end

      # -v, --invert-match
      #        Selected lines are those not matching any of the specified patterns.
      # opts.on("-v PATTERN") do |pattern|
      #   routes_filter = pattern
      # end

    end.parse!(ARGV.reject { |x| x == "routes" })

    puts inspector.format(Routes2spec::RequestSpecFormatter.new, routes_filter)

    exit 0 # ensure extra arguments aren't interpreted as Rake tasks
  end
end
