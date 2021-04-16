require "chef-cli/command/base"

module ChefCLI
  module Command
    class TestCommand < ChefCLI::Command::Base

      def self.reset!
        @test_result = nil
      end

      def self.test_result
        @test_result
      end

      def self.test_result=(result)
        @test_result = result
      end

      def run(params)
        self.class.test_result = { status: :success, params: params }
        23
      end

    end
  end
end
