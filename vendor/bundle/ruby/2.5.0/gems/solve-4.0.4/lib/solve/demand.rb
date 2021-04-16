module Solve
  class Demand
    # A reference to the solver this demand belongs to
    #
    # @return [Solve::RubySolver,Solve::GecodeSolver]
    attr_reader :solver

    # The name of the artifact this demand is for
    #
    # @return [String]
    attr_reader :name

    # The acceptable constraint of the artifact this demand is for
    #
    # @return [Semverse::Constraint]
    attr_reader :constraint

    # @param [Solve::RubySolver,Solve::GecodeSolver] solver
    # @param [#to_s] name
    # @param [Semverse::Constraint, #to_s] constraint
    def initialize(solver, name, constraint = Semverse::DEFAULT_CONSTRAINT)
      @solver     = solver
      @name       = name
      @constraint = Semverse::Constraint.coerce(constraint)
    end

    def to_s
      "#{name} (#{constraint})"
    end

    def ==(other)
      other.is_a?(self.class) &&
        name == other.name &&
        constraint == other.constraint
    end
    alias_method :eql?, :==
  end
end
