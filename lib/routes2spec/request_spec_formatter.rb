# frozen_string_literal: true

module Routes2spec
  # Routes2spec::RequestSpecFormatter class
  class RequestSpecFormatter
    SUPPORTED_VERBS = %w[get post patch put delete].freeze

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
      routes = routes.select do |r|
        is_valid = r[:reqs].include?("#") && !r[:reqs].start_with?("#<")
        Routes2spec.log "Skip. Unsupported reqs! `#{r[:reqs]}`" unless is_valid
        is_valid
      end
      grouped = routes.group_by { |r| r[:reqs].split("#").first }
      Routes2spec.log_debug "grouped: #{grouped}"
      @results << grouped.map do |controller, grouped_routes|
        # TODO: support redirect. ex: {"redirect(301, https://example.com)"=>[{:name=>"example", :verb=>"GET", :path=>"/example(.:format)", :reqs=>"redirect(301, https://example.com)"}]}

        namespaces = controller.split("/")
        controller_name = namespaces.map(&:camelize).join("::")
        group_name = namespaces.pop
        Routes2spec.log_debug "namespaces: #{namespaces}, group_name: #{group_name}, controller_name: #{controller_name}"
        unless group_name
          Routes2spec.log "Skip. Invalid controller format! `#{controller}`"
          next
        end
        routes = grouped_routes.map do |r|
          verb = r[:verb]&.downcase # GET|POST
          path = r[:path].gsub("(.:format)", "")
          param_names = path.scan %r{(?<=/:).+?(?=/|\z)}
          params_str = param_names.map{|name| "#{name}: \"#{name}\"" }.join(", ")
          path_name = r[:name] || ""
          path_name = grouped_routes.find{ _1[:path] == r[:path] && !_1[:name].empty? }&.fetch(:name) || "" if path_name.empty?
          Routes2spec.log_debug "verb: #{verb}, path: #{path}, path_name: #{path_name}, @opts: #{@opts}"
          if path_name.empty?
            Routes2spec.log "Skip. No path name! `#{verb&.upcase} #{path}`"
            next
          end
          unless SUPPORTED_VERBS.include?(verb)
            Routes2spec.log "Skip. Unsupported verb! `#{verb&.upcase} #{path}`"
            next
          end
          if !@opts[:verb].nil? && @opts[:verb].downcase != verb
            Routes2spec.log "Skip. Not matched specified verb(#{@opts[:verb].upcase})! `#{verb&.upcase} #{path}`"
            next
          end
          endpoint, constraints = r[:reqs].split(" ")
          Routes2spec.log_debug "endpoint: #{endpoint}, constraints: #{constraints}"
          # TODO: insert constraints to routing spec
          status = @opts[:symbol_status] ? SYMBOL_STATUS[verb.to_sym] : STATUS[verb.to_sym]
          use_literal_path = @opts[:literal_path] || false
          path_helper_str = "#{path_name}_path#{params_str.empty? ? "" : "(#{params_str})"}"
          literal_path_str = "\"#{path}\""
          path_str = use_literal_path ? literal_path_str : path_helper_str
          r.merge(
            path: path,
            path_str: path_str,
            path_name: path_name,
            params_str: params_str,
            reqs: r[:reqs],
            endpoint: endpoint,
            constraints: constraints || "",
            status: status,
          )
        end.compact
        if routes.empty?
          Routes2spec.log "Skip. Empty routes! `#{controller}`"
          next
        end
        pending = @opts[:pending] || false
        template_path = File.expand_path(File.join(File.dirname(__FILE__), "templates/request_spec.rb.erb"))
        content = ERB.new(File.read(template_path)).result(binding)
        routing_template_path = File.expand_path(File.join(File.dirname(__FILE__), "templates/routing_spec.rb.erb"))
        routing_content = ERB.new(File.read(routing_template_path)).result(binding)
        {
          name: group_name,
          namespaces: namespaces,
          content: content,
          routing_content: routing_content,
        }
      end.compact
    end

    def header(routes)
    end

    def no_routes(*)
    end
  end
end
