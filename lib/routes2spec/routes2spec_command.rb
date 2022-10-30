# frozen_string_literal: true

require "rails/command"
require_relative "./request_spec_formatter"

module Routes2spec
  # ref. https://github.com/rails/rails/blob/7-0-stable/railties/lib/rails/commands/routes/routes_command.rb
  class Routes2specCommand < Rails::Command::Base
    class_option :controller, aliases: "-c", desc: "Filter by a specific controller, e.g. PostsController or Admin::PostsController."
    class_option :grep, aliases: "-g", desc: "Grep routes by a specific pattern."
    # class_option :expanded, type: :boolean, aliases: "-E", desc: "Print routes expanded vertically with parts explained."
    class_option :symbol_status, desc: "TODO"
    class_option :overwrite, desc: "TODO"
    class_option :force_overwrite, desc: "TODO"

    def perform(*)
      require_application_and_environment!
      require "action_dispatch/routing/inspector"

      # say inspector.format(formatter, routes_filter)
      results = inspector.format(formatter, routes_filter)
      results.each do |result|
        outfile = Rails.root.join("spec/requests", *result[:namespaces], "#{result[:name].underscore}_spec.rb")
        FileUtils.mkdir_p(File.dirname(outfile))

        unless File.exist?(outfile)
          Routes2spec.log "Generating: #{outfile}"
          File.write(outfile, result[:content], mode: "w")
          next
        end

        if options.key?("force_overwrite")
          Routes2spec.log "Overwriting: #{outfile}"
          File.write(outfile, result[:content], mode: "w")
          next
        end

        Routes2spec.log "Already exists: #{outfile}"
        if options.key?("overwrite")
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
    end

    private

    def inspector
      ActionDispatch::Routing::RoutesInspector.new(Rails.application.routes.routes)
    end

    def formatter
      Routes2spec::RequestSpecFormatter.new(formatter_opts)
    end

    def routes_filter
      if Rails::VERSION::MAJOR >= 6
        options.symbolize_keys.slice(:controller, :grep)
      else
        options.key?("controller") ?
          options.symbolize_keys.slice(:controller) :
          options.fetch("grep", nil)
      end
    end

    def formatter_opts
      options.symbolize_keys.slice(:symbol_status)
    end
  end
end
