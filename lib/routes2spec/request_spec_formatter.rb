# frozen_string_literal: true

module Routes2spec
  # Routes2spec::RequestSpecFormatter class
  class RequestSpecFormatter
    STATUS = {
      get: 200,
      post: 201,
      patch: 200,
      put: 200,
      delete: 204,
    }.tap{ _1.default = 200 }.freeze

    SYMBOL_STATUS = {
      get: ":ok",
      post: ":created",
      patch: ":ok",
      put: ":ok",
      delete: ":no_content",
    }.tap{ _1.default = ":ok" }.freeze

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
        controller_name = namespaces.pop
        unless controller_name
          Routes2spec.log_debug "No controller name! #{namespaces}"
          next
        end
        routes = routes.map do |r|
          verb = r[:verb]&.downcase # GET|POST
          path = r[:path].gsub("(.:format)", "")
          path_name = r[:name] || ""
          path_name = routes.find{ _1[:path] == r[:path] && !_1[:name].empty? }&.fetch(:name) || "" if path_name.empty?
          Routes2spec.log_debug "verb: #{verb}, path: #{path}, path_name: #{path_name}"
          if path_name.empty?
            Routes2spec.log_debug "No path name!"
            next
          end
          unless %w[get post patch put delete].include?(verb)
            Routes2spec.log_debug "Unsupported verb! #{verb}"
            next
          end
          status = @opts[:symbol_status] ? SYMBOL_STATUS[verb.to_sym] : STATUS[verb.to_sym]
          r.merge(
            path: path,
            path_name: path_name,
            status: status
          )
        end.compact
        template_path = File.expand_path(File.join(File.dirname(__FILE__), "templates/request_spec.rb.erb"))
        content = ERB.new(File.read(template_path)).result(binding)
        {
          name: controller_name,
          namespaces: namespaces,
          content: content,
        }
      end.compact
    end

    def header(routes)
    end

    def no_routes(*)
    end
  end
end
