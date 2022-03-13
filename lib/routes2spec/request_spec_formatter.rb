# frozen_string_literal: true

module Routes2spec
  class RequestSpecFormatter
    def initialize
    end

    def result
    end

    def section_title(title)
    end

    def section(routes)
      grouped = routes.group_by { |r| r[:reqs].split("#").first }
      Routes2spec.log_debug grouped
      grouped.each do |controller, routes|
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
          path_helper = r[:name]
          unless path_helper
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
          r.merge(
            path: path,
            path_helper: path_helper,
            status: status,
          )
        end.compact
        template_path = File.expand_path(File.join(File.dirname(__FILE__), "templates/request_spec.rb.erb"))
        result = ERB.new(File.read(template_path)).result(binding)
        outfile = Rails.root.join("spec/requests", *namespaces, "#{name.underscore}_spec.rb")
        FileUtils.mkdir_p(File.dirname(outfile))
        if File.exist?(outfile)
          Routes2spec.log "Already exists: #{outfile}"
          # print "Overwrite? (y/n) "
          # res = STDIN.gets.chomp
          # if res.downcase == "y"
          #   File.write(outfile, result, mode: "w")
          # end
        else
          Routes2spec.log "Generating: #{outfile}"
          File.write(outfile, result, mode: "w")
        end
      end
    end

    def header(routes)
    end

    def no_routes(routes)
    end
  end
end
