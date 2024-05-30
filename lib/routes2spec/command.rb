# frozen_string_literal: true

require "rails/command"
require_relative "./request_spec_formatter"

module Routes2spec
  # Routes2spec::Command class
  class Command < Rails::Command::Base
    SUPPORTED_VERBS = Routes2spec::RequestSpecFormatter::SUPPORTED_VERBS

    class_option :help, aliases: "-h", banner: "", desc: "Show this message."
    class_option :version, aliases: "-V", banner: "", desc: "Show version."

    class_option :binstubs, banner: "", desc: "Generate binstubs."

    class_option :controller, aliases: "-c",
                              desc: "Filter by a specific controller, e.g. PostsController or Admin::PostsController."
    class_option :grep, aliases: "-g", desc: "Grep routes by a specific pattern."
    class_option :symbol_status, banner: "", desc: "Use symbols for http status."
    class_option :overwrite, banner: "", desc: "Prompts for confirmation to overwrite each file if it already exists."
    class_option :force_overwrite, banner: "", desc: "Forcibly overwrites existing files without confirmation."
    class_option :pending, banner: "", desc: "Mark examples as pending."
    class_option :routing, type: :boolean, defalut: false, desc: "Generate routing specs."
    class_option :verb, desc: "Generate only specific verb. Supported verbs: [#{SUPPORTED_VERBS.join(", ")}]"

    class << self
      def executable
        "routes2spec"
      end
    end

    def perform(*)
      if options.version?
        say "Routes2spec: #{Routes2spec::VERSION}"
        exit 0
      end

      if options.binstubs?
        make_binstubs
        exit 0
      end

      if options.verb? && !SUPPORTED_VERBS.include?(options.verb&.downcase)
        say "Specified verb(#{options.verb}) is not supported! Supported verbs: [#{SUPPORTED_VERBS.join(", ")}]"
        exit 1
      end

      require_application_and_environment!
      require "action_dispatch/routing/inspector"

      results = inspector.format(formatter, routes_filter)
      results.each do |result|
        relative_path = File.join("spec/requests", *result[:namespaces], "#{result[:name].underscore}_spec.rb")
        writing_file(relative_path, result[:content])

        relative_path = File.join("spec/routing", *result[:namespaces], "#{result[:name].underscore}_spec.rb")
        writing_file(relative_path, result[:routing_content]) if options.routing?
      end
    end
    # https://github.com/rails/rails/blob/v7.0.4/railties/lib/rails/command/base.rb#L144
    alias_method "routes2spec", "perform"

    private

    def writing_file(relative_path, content)
      outfile = Rails.root.join(relative_path)
      FileUtils.mkdir_p(File.dirname(outfile))

      unless File.exist?(outfile)
        Routes2spec.log "Generating: #{relative_path}"
        File.write(outfile, content, mode: "w")
        return
      end

      if options.force_overwrite?
        Routes2spec.log "Overwriting: #{relative_path}"
        File.write(outfile, content, mode: "w")
        return
      end

      Routes2spec.log "Already exists: #{relative_path}"

      if options.overwrite? && file_collision(relative_path)
        say "Overwriting..."
        File.write(outfile, content, mode: "w")
      end
    end

    def make_binstubs
      require "fileutils"
      FileUtils.mkdir_p("bin")
      outfile = File.expand_path("bin/routes2spec")
      file_path = File.expand_path(File.join(File.dirname(__FILE__), "binstubs/routes2spec"))
      content = File.read(file_path)
      File.write(outfile, content, mode: "w")
      FileUtils.chmod("+x", outfile)
      Routes2spec.log "Generated: bin/routes2spec"
    end

    def inspector
      ActionDispatch::Routing::RoutesInspector.new(routes)
    end

    def routes
      # TODO: support engine routes.
      Rails.application.routes.routes.reject{ _1.app.engine? || _1.internal }
    end

    def formatter
      Routes2spec::RequestSpecFormatter.new(formatter_opts)
    end

    def routes_filter
      options.symbolize_keys.slice(:controller, :grep)
    end

    def formatter_opts
      options.symbolize_keys.slice(:symbol_status, :pending, :verb)
    end
  end
end
