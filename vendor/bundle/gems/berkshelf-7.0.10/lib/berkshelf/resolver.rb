module Berkshelf
  class Resolver

    require_relative "resolver/graph"

    extend Forwardable

    # @return [Berksfile]
    attr_reader :berksfile

    # @return [Resolver::Graph]
    attr_reader :graph

    # @return [Array<Dependency>]
    #   an array of dependencies that must be satisfied
    attr_reader :demands

    # @param [Berksfile] berksfile
    # @param [Array<Dependency>, Dependency] demands
    #   a dependency, or array of dependencies, which must be satisfied
    def initialize(berksfile, demands = [])
      @berksfile = berksfile
      @graph     = Graph.new
      @demands   = []

      Array(demands).each { |demand| add_demand(demand) }
      compute_solver_engine(berksfile)
    end

    # Add the given dependency to the collection of demands
    #
    # @param [Dependency] demand
    #   add a dependency that must be satisfied to the graph
    #
    # @raise [DuplicateDemand]
    #
    # @return [Array<Dependency>]
    def add_demand(demand)
      if has_demand?(demand)
        raise DuplicateDemand, "A demand named '#{demand.name}' is already present."
      end

      demands.push(demand)
    end

    # Add dependencies of a locally cached cookbook which will take precedence over anything
    # found in the universe.
    #
    # @param [CachedCookbook] cookbook
    #
    # @return [Hash]
    def add_explicit_dependencies(cookbook)
      graph.populate_local(cookbook)
    end

    # An array of arrays containing the name and constraint of each demand
    #
    # @note this is the format that Solve uses to determine a solution for the graph
    #
    # @return [Array<String, String>]
    def demand_array
      demands.collect do |demand|
        constraint = demand.locked_version || demand.version_constraint
        [demand.name, constraint]
      end
    end

    # Finds a solution for the currently added dependencies and their dependencies and
    # returns an array of CachedCookbooks.
    #
    # @raise [NoSolutionError] when a solution could not be found for the given demands
    #
    # @return [Array<Array<String, String, Dependency>>]
    def resolve
      graph.populate_store
      graph.populate(berksfile.sources)

      Solve.it!(graph, demand_array, ENV["DEBUG_RESOLVER"] ? { ui: Berkshelf.ui } : {}).collect do |name, version|
        dependency = get_demand(name) || Dependency.new(berksfile, name)
        dependency.locked_version = version

        dependency
      end
    rescue Solve::Errors::NoSolutionError => e
      raise NoSolutionError.new(demands, e)
    end

    # Retrieve the given demand from the resolver
    #
    # @param [Dependency, #to_s] demand
    #   name of the dependency to return
    #
    # @return [Dependency]
    def [](demand)
      name = demand.respond_to?(:name) ? demand.name : demand.to_s
      demands.find { |d| d.name == name }
    end
    alias_method :get_demand, :[]

    # Check if the given demand has been added to the resolver
    #
    # @param [Dependency, #to_s] demand
    #   the demand or the name of the demand to check for
    def has_demand?(demand)
      !get_demand(demand).nil?
    end

    # Look at berksfile's solvers, and ask Solve#engine= for the right one,
    # swallowing any exceptions if it's preferred but not required
    #
    # @param [Berksfile] berksfile
    def compute_solver_engine(berksfile)
      if berksfile.required_solver
        begin
          Solve.engine = berksfile.required_solver
        rescue Solve::Errors::InvalidEngine => e
          raise ArgumentError, e.message
        end
      elsif berksfile.preferred_solver
        begin
          Solve.engine = berksfile.preferred_solver
        rescue
          # We should log this, but Berkshelf.log.warn and Berkshelf.formatter.warn
          # both seem inappropriate here.
          # "  Preferred solver ':#{berksfile.preferred_solver}' unavailable"
        end
      end
      # We should log this, but Berkshelf.log.info and Berkshelf.formatter.msg
      # both seem inappropriate here.
      # "  Selected dependency solver engine ':#{Solve.engine}'"
    end
  end
end
