# frozen_string_literal: true

module Routes2spec
  class RequestSpecFormatter
    STATUS = {
      get: 200,
      post: 201,
      delete: 204,
    }.freeze
    SYMBOL_STATUS = {
      get: ":ok",
      post: ":created",
      delete: ":no_content",
    }.freeze

    def initialize(opts = {})
      @results = []
      @opts = opts
    end

    def result
      @results.flatten
    end

    def section_title(title)
    end

    def section(routes)
      grouped = routes.group_by { |r| r[:reqs].split("#").first }
      Routes2spec.log_debug grouped
      @results << grouped.map do |controller, routes|
        next unless routes.first[:reqs].include?("#")

        namespaces = controller.split("/")
        name = namespaces.pop
        unless name
          Routes2spec.log_debug "No name!"
          next
        end
        routes = routes.map do |r|
          verb = r[:verb]&.downcase # GET|POST
          path = r[:path].gsub("(.:format)", "")
          path_helper = r[:name] || ""
          if path_helper.empty?
            Routes2spec.log_debug "No path name!"
            next
          end
          unless %w[get post patch put delete].include?(verb)
            Routes2spec.log_debug "Unsupported verb! #{verb}"
            next
          end
          status = @opts[:symbol_status] ? SYMBOL_STATUS.fetch(verb.to_sym, ":ok") : STATUS.fetch(verb.to_sym, 200)
          r.merge(
            path: path,
            path_helper: path_helper,
            status: status,
          )
        end.compact
        template_path = File.expand_path(File.join(File.dirname(__FILE__), "templates/request_spec.rb.erb"))
        content = ERB.new(File.read(template_path)).result(binding)
        {
          name: name,
          namespaces: namespaces,
          content: content,
        }
      end.compact
    end

    def header(routes)
    end

    def no_routes(routes)
    end
  end
end
