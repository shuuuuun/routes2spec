# frozen_string_literal: true

# https://github.com/rails/rails/blob/7-0-stable/actionpack/lib/action_dispatch/routing/inspector.rb

require "action_dispatch/routing/inspector"

module Routes2spec
  class RoutesInspector < ActionDispatch::Routing::RoutesInspector
    def format(formatter, filter = {})
      routes_to_display = filter_routes(normalize_filter(filter))
      routes = collect_routes(routes_to_display)
      # binding.pry

      # routes_to_display.collect do |route|
      #   ActionDispatch::Routing::RouteWrapper.new(route)
      # end.reject(&:internal?).collect do |route|
      #   collect_engine_routes(route)

      #   { name: route.name,
      #     verb: route.verb,
      #     path: route.path,
      #     reqs: route.reqs }
      # end

      if routes.none?
        formatter.no_routes(collect_routes(@routes), filter)
        return formatter.result
      end

      formatter.header routes
      formatter.section routes

      @engines.each do |name, engine_routes|
        formatter.section_title "Routes for #{name}"
        formatter.section engine_routes
      end

      formatter.result

      # super
    end

    private

    # def collect_routes(routes)
    #   routes.collect do |route|
    #     ActionDispatch::Routing::RouteWrapper.new(route)
    #   end.reject(&:internal?).collect do |route|
    #     collect_engine_routes(route)

    #     { name: route.name,
    #       verb: route.verb,
    #       path: route.path,
    #       reqs: route.reqs }
    #   end
    # end
  end
end
