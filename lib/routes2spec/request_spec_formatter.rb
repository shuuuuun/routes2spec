# frozen_string_literal: true

module Routes2spec
  class RequestSpecFormatter
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
          status =
            case verb
            when "post"
              201
            when "delete"
              204
            else
              200
            end
          if @opts[:symbol_status]
            status =
              case verb
              when "post"
                ":created"
              when "delete"
                ":no_content"
              else
                ":ok"
              end
          end
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
