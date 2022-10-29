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

    if Rails::VERSION::MAJOR > 5
      routes_filter = {}
    else
      routes_filter = nil
    end
    overwrite = false
    force_overwrite = false
    formatter_opts = {
      symbol_status: false,
    }

    OptionParser.new do |opts|
      opts.banner = "Usage: rails routes:request_spec [options]"

      Rake.application.standard_rake_options.each { |args| opts.on(*args) }

      opts.on("-V", "--version") do
        $stdout.puts "Routes2spec: #{Routes2spec::VERSION}"
        exit 0
      end

      opts.on("--overwrite") do |boolean|
        overwrite = boolean
      end
      opts.on("--force-overwrite") do |boolean|
        force_overwrite = boolean
      end

      opts.on("-c CONTROLLER") do |controller|
        routes_filter = { controller: controller }
      end

      opts.on("-g PATTERN") do |pattern|
        if Rails::VERSION::MAJOR > 5
          routes_filter = { grep: pattern }
        else
          routes_filter = pattern
        end
      end

      # -v, --invert-match
      #        Selected lines are those not matching any of the specified patterns.
      # opts.on("-v PATTERN") do |pattern|
      #   routes_filter = pattern
      # end

      opts.on("--symbol-status") do |boolean|
        formatter_opts[:symbol_status] = boolean
      end
    end.parse!(ARGV.reject { |x| x == "routes:request_spec" }.reject { |x| x == "--" })

    results = inspector.format(Routes2spec::RequestSpecFormatter.new(formatter_opts), routes_filter)
    results.each do |result|
      outfile = Rails.root.join("spec/requests", *result[:namespaces], "#{result[:name].underscore}_spec.rb")
      FileUtils.mkdir_p(File.dirname(outfile))

      unless File.exist?(outfile)
        Routes2spec.log "Generating: #{outfile}"
        File.write(outfile, result[:content], mode: "w")
        next
      end

      if force_overwrite
        Routes2spec.log "Overwriting: #{outfile}"
        File.write(outfile, result[:content], mode: "w")
        next
      end

      Routes2spec.log "Already exists: #{outfile}"
      if overwrite
        print "Overwrite? (y/n/q) "
        res = $stdin.gets.chomp
        case res.downcase
        when "y"
          File.write(outfile, result[:content], mode: "w")
        when "q"
          exit 0
        else
          next
        end
      end
    end

    exit 0 # ensure extra arguments aren't interpreted as Rake tasks
  end
end
