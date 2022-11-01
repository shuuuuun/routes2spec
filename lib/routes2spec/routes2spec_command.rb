# frozen_string_literal: true

require "rails/command"
require_relative "./request_spec_formatter"

module Routes2spec
  # ref. https://github.com/rails/rails/blob/7-0-stable/railties/lib/rails/commands/routes/routes_command.rb
  class Routes2specCommand < Rails::Command::Base
    class_option :binstubs, desc: "TODO"
    class_option :controller, aliases: "-c", desc: "Filter by a specific controller, e.g. PostsController or Admin::PostsController."
    class_option :grep, aliases: "-g", desc: "Grep routes by a specific pattern."
    class_option :symbol_status, desc: "TODO"
    class_option :overwrite, desc: "TODO"
    class_option :force_overwrite, desc: "TODO"

    def perform(*)
      if options.binstubs?
        make_binstubs
        exit 0
      end

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

        if options.force_overwrite?
          Routes2spec.log "Overwriting: #{outfile}"
          File.write(outfile, result[:content], mode: "w")
          next
        end

        Routes2spec.log "Already exists: #{outfile}"
        if options.overwrite?
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

    def make_binstubs
      require "fileutils"
      FileUtils.mkdir_p("bin")
      outfile = File.expand_path("bin/routes2spec")
      file_path = File.expand_path(File.join(File.dirname(__FILE__), "binstubs/routes2spec"))
      content = File.read(file_path)
      File.write(outfile, content, mode: "w")
      Routes2spec.log "Generated: bin/routes2spec"
    end

    def inspector
      ActionDispatch::Routing::RoutesInspector.new(Rails.application.routes.routes)
    end

    def formatter
      Routes2spec::RequestSpecFormatter.new(formatter_opts)
    end

    def routes_filter
      if Rails::VERSION::MAJOR >= 6
        options.slice(:controller, :grep)
      else
        options.controller? ?
          options.slice(:controller) :
          options.fetch(:grep, nil)
      end
    end

    def formatter_opts
      options.slice(:symbol_status)
    end
  end
end
