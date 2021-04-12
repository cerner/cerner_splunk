module Mixlib
  module Authentication
    module NullLogger

      attr_accessor :level

      %i{trace debug info warn error fatal}.each do |method_name|
        class_eval(<<-METHOD_DEFN, __FILE__, __LINE__)
          def #{method_name}(msg=nil, &block)
            true
          end
        METHOD_DEFN
      end

      %i{trace? debug? info? warn? error? fatal?}.each do |method_name|
        class_eval(<<-METHOD_DEFN, __FILE__, __LINE__)
          def #{method_name}
            false
          end
        METHOD_DEFN
      end
    end
  end
end
