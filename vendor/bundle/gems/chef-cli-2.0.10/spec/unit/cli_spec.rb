# Copyright:: Copyright (c) 2014-2018 Chef Software Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "spec_helper"
require "stringio"
require "chef-cli/cli"
require "unit/fixtures/command/cli_test_command"

describe ChefCLI::CLI do

  let(:argv) { [] }

  # Setup a new commands map so we control what subcommands exist. Otherwise
  # we'd have to update this test for every new subcommand we add or code the
  # tests defensively.
  let(:commands_map) { ChefCLI::CommandsMap.new }

  let(:stdout_io) { StringIO.new }
  let(:stderr_io) { StringIO.new }

  def stdout
    stdout_io.string
  end

  def stderr
    stderr_io.string
  end

  let(:base_help_message) do
    <<~E
      Usage:
          chef -h/--help
          chef -v/--version
          chef command [arguments...] [options...]


      Available Commands:
          gem      Runs the `gem` command in context of the embedded ruby
          example  Example subcommand for testing
    E
  end

  let(:version_message) { "#{ChefCLI::Dist::PRODUCT} version: #{ChefCLI::VERSION}\n" }

  def run_cli(expected_exit_code)
    expect(cli).to receive(:exit).with(expected_exit_code)
    expect(cli).to receive(:sanity_check!)
    cli.run
  end

  def run_cli_with_sanity_check(expected_exit_code)
    expect(cli).to receive(:exit).with(expected_exit_code)
    cli.run
  end

  def run_cli_and_validate_tool_versions
    full_version_message = version_message
    tools.each do |name, details|
      expect(cli).to receive(:shell_out).with("#{details["command"]} --version").and_return(mock_shell_out(0, "#{details["version_output"]}", ""))
      full_version_message += "#{name} version: #{details["expected_version"]}\n"
    end
    run_cli(0)
    expect(stdout).to eq(full_version_message)
  end

  def mock_shell_out(exitstatus, stdout, stderr)
    shell_out = double("mixlib_shell_out")
    allow(shell_out).to receive(:exitstatus).and_return(exitstatus)
    allow(shell_out).to receive(:stdout).and_return(stdout)
    allow(shell_out).to receive(:stderr).and_return(stderr)
    shell_out
  end

  subject(:cli) do
    ChefCLI::CLI.new(argv).tap do |c|
      allow(c).to receive(:commands_map).and_return(commands_map)
      allow(c).to receive(:stdout).and_return(stdout_io)
      allow(c).to receive(:stderr).and_return(stderr_io)
    end
  end

  before do
    commands_map.builtin "gem", :GemForwarder, require_path: "chef-cli/command/gem",
                                               desc: "Runs the `gem` command in context of the embedded ruby"

    commands_map.builtin "example", :TestCommand, require_path: "unit/fixtures/command/cli_test_command",
                                                  desc: "Example subcommand for testing"
  end

  context "given no arguments or options" do

    it "prints the help output" do
      run_cli(0)
      expect(stdout).to eq(base_help_message)
    end

  end

  context "given -h" do
    let(:argv) { %w{-h} }

    it "prints the help output" do
      run_cli(0)
      expect(stdout).to eq(base_help_message)
    end
  end

  context "given -v" do
    let(:argv) { %w{-v} }

    context "#via_version_manifest" do
      let(:mocked_version_manifest_json) do
        <<~E
          {
            "manifest_format": 2,
            "build_version": "d.e.v"
          }
        E
      end

      let(:mocked_gem_version_manifest_json) do
        <<~E
          {
            "chef-cli": [
              "0.0.1"
            ],
            "chef": [
              "0.0.2"
            ],
            "inspec": [
              "0.0.3"
            ],
            "test-kitchen": [
              "0.0.4"
            ],
            "cookstyle": [
              "0.0.6"
            ]
          }
        E
      end

      # rubocop:disable Layout/TrailingWhitespace
      let(:full_table_with_version_message) do
        <<~E
          Chef Workstation version: d.e.v
          Chef Infra Client version: 0.0.2
          Chef InSpec version: 0.0.3
          Chef CLI version: 0.0.1
          Test Kitchen version: 0.0.4
          Cookstyle version: 0.0.6
        E
      end

      let(:full_table_with_unknown_version_message) do
        <<~E
          Chef Workstation version: unknown
          Chef Infra Client version: unknown
          Chef InSpec version: unknown
          Chef CLI version: unknown
          Test Kitchen version: unknown
          Cookstyle version: unknown
        E
      end

      before do
        allow(cli).to receive(:omnibus_install?).and_return true
        allow(cli).to receive(:read_version_manifest_json).and_return(mocked_version_manifest_json)
        allow(cli).to receive(:read_gem_version_manifest_json).and_return(mocked_gem_version_manifest_json)
      end

      it "does not print versions of tools with missing or errored tools" do
        allow(cli).to receive(:read_gem_version_manifest_json).and_return("{}")
        allow(cli).to receive(:read_version_manifest_json).and_return("{}")
        run_cli(0)
        expect(stdout).to eq(full_table_with_unknown_version_message)
      end

      it "prints a table with the version of all the tools" do
        run_cli(0)
        expect(stdout).to eq(full_table_with_version_message)
      end
    end

    context "#via_shell_out" do
      let(:tools) do
        {
          "Chef Infra Client" => {
            "command" => "chef-client",
            "version_output" => "Chef Infra Client: 15.0.300",
            "expected_version" => "15.0.300",
          },
          "Chef InSpec" => {
            "command" => "inspec",
            "version_output" => "4.6.2\n\nYour version of InSpec is out of date! The latest version is 4.6.4.",
            "expected_version" => "4.6.2",
          },
          "Test Kitchen" => {
            "command" => "kitchen",
            "version_output" => "Test Kitchen version 2.2.5",
            "expected_version" => "2.2.5",
          },
          "Cookstyle" => {
            "command" => "cookstyle",
            "version_output" => "Cookstyle 4.0.0\n  * RuboCop 0.62.0",
            "expected_version" => "4.0.0",
          },
        }
      end

      it "does not print versions of tools with missing or errored tools" do
        full_version_message = version_message
        tools.each do |name, details|
          if name == "inspec"
            expect(cli).to receive(:shell_out).with("#{details["command"]} --version").and_return(mock_shell_out(1, "#{details["version_output"]}", ""))
            full_version_message += "#{name} version: ERROR\n"
          else
            expect(cli).to receive(:shell_out).with("#{details["command"]} --version").and_return(mock_shell_out(0, "#{details["version_output"]}", ""))
            full_version_message += "#{name} version: #{details["expected_version"]}\n"
          end
        end
        run_cli(0)
        expect(stdout).to eq(full_version_message)
      end

      it "prints the version and versions of chef-cli tools" do
        run_cli_and_validate_tool_versions
      end
    end
  end

  context "given an invalid option" do

    let(:argv) { %w{-nope} }

    it "prints an 'invalid option message and the help output, then exits non-zero" do
      run_cli(1)
      expect(stdout).to eq(base_help_message)
      expect(stderr).to eq("invalid option: -nope\n")
    end

  end

  context "given an invalid/unknown subcommand" do
    let(:argv) { %w{ancient-aliens} }

    it "prints an 'unknown command' message and the help output" do
      expected_err = "Unknown command `ancient-aliens'.\n"

      run_cli(1)

      expect(stderr).to eq(expected_err)
      expect(stdout).to eq(base_help_message)
    end

  end

  context "given a valid subcommand" do
    let(:argv) { %w{example with some args --and-an-option} }

    def test_result
      ChefCLI::Command::TestCommand.test_result
    end

    before do
      ChefCLI::Command::TestCommand.reset!
    end

    it "runs the subcommand" do
      run_cli(23)
      expect(test_result[:status]).to eq(:success)
    end

    it "exits with the return code given by the subcommand" do
      run_cli(23)
    end

    it "passes arguments and options to the subcommand" do
      params = %w{with some args --and-an-option}
      run_cli(23)
      expect(test_result[:params]).to eq(params)
    end
  end

  context "sanity_check!" do

    before do
      allow(Gem).to receive(:ruby).and_return(ruby_path)
      allow(cli).to receive(:package_home).and_return("/opt/chef-workstation")
    end

    context "when installed via omnibus" do
      before do
        allow(cli).to receive(:omnibus_install?).and_return true
      end

      context "on unix" do

        let(:ruby_path) { "/opt/chef-workstation/embedded/bin/ruby" }
        before do
          stub_const("File::PATH_SEPARATOR", ":")
          allow(Chef::Util::PathHelper).to receive(:cleanpath) do |path|
            path
          end
        end

        it "complains if embedded is first" do
          allow(cli).to receive(:env).and_return({ "PATH" => "/opt/chef-workstation/embedded/bin:/opt/chef-workstation/bin" })
          allow(cli).to receive(:omnibus_embedded_bin_dir).and_return("/opt/chef-workstation/embedded/bin")
          allow(cli).to receive(:omnibus_bin_dir).and_return("/opt/chef-workstation/bin")
          run_cli_with_sanity_check(0)
          expect(stdout).to eq(base_help_message)
          expect(stderr).to include("please reverse that order")
          expect(stderr).to include("chef shell-init")
        end

        it "complains if only embedded is present" do
          allow(cli).to receive(:env).and_return({ "PATH" => "/opt/chef-workstation/embedded/bin" })
          allow(cli).to receive(:omnibus_embedded_bin_dir).and_return("/opt/chef-workstation/embedded/bin")
          allow(cli).to receive(:omnibus_bin_dir).and_return("/opt/chef-workstation/bin")
          run_cli_with_sanity_check(0)
          expect(stdout).to eq(base_help_message)
          expect(stderr).to include("you must add")
          expect(stderr).to include("chef shell-init")
        end

        it "passes when both are present in the correct order" do
          allow(cli).to receive(:env).and_return({ "PATH" => "/opt/chef-workstation/bin:/opt/chef-workstation/embedded/bin" })
          allow(cli).to receive(:omnibus_embedded_bin_dir).and_return("/opt/chef-workstation/embedded/bin")
          allow(cli).to receive(:omnibus_bin_dir).and_return("/opt/chef-workstation/bin")
          run_cli_with_sanity_check(0)
          expect(stdout).to eq(base_help_message)
        end

        it "passes when only the omnibus bin dir is present" do
          allow(cli).to receive(:env).and_return({ "PATH" => "/opt/chef-workstation/bin" })
          allow(cli).to receive(:omnibus_embedded_bin_dir).and_return("/opt/chef-workstation/embedded/bin")
          allow(cli).to receive(:omnibus_bin_dir).and_return("/opt/chef-workstation/bin")
          run_cli_with_sanity_check(0)
          expect(stdout).to eq(base_help_message)
        end
      end

      context "on windows" do

        let(:ruby_path) { "c:/opscode/chef-workstation/embedded/bin/ruby.exe" }
        let(:omnibus_root) { "c:/opscode/chef-workstation" }

        before do
          # Would be preferable not to stub this, but `File.expand_path` does
          # weird things with windows paths on unix machines.
          #
          # I manually verified the behavior:
          #
          #   $ /c/opscode/chef-workstation/embedded/bin/ruby -e 'p File.expand_path(File.join(Gem.ruby, "..", "..", ".."))'
          #   "c:/opscode/chef-workstation"
          allow(cli).to receive(:expected_omnibus_root).and_return(ruby_path)
          allow(cli).to receive(:omnibus_install?).and_return(true)
          allow(Chef::Platform).to receive(:windows?).and_return(true)
          stub_const("File::PATH_SEPARATOR", ";")
          allow(Chef::Util::PathHelper).to receive(:cleanpath) do |path|
            path.tr "/", "\\"
          end
        end

        it "complains if embedded is first" do
          allow(cli).to receive(:env).and_return({ "PATH" => 'C:\opscode\chef-workstation\embedded\bin;C:\opscode\chef-workstation\bin' })
          allow(cli).to receive(:omnibus_embedded_bin_dir).and_return("c:/opscode/chef-workstation/embedded/bin")
          allow(cli).to receive(:omnibus_bin_dir).and_return("c:/opscode/chef-workstation/bin")
          run_cli_with_sanity_check(0)
          expect(stdout).to eq(base_help_message)
          expect(stderr).to include("please reverse that order")
          expect(stderr).to include("chef shell-init")
        end

        it "complains if only embedded is present" do
          allow(cli).to receive(:env).and_return({ "PATH" => 'C:\opscode\chef-workstation\embedded\bin' })
          allow(cli).to receive(:omnibus_embedded_bin_dir).and_return("c:/opscode/chef-workstation/embedded/bin")
          allow(cli).to receive(:omnibus_bin_dir).and_return("c:/opscode/chef-workstation/bin")
          run_cli_with_sanity_check(0)
          expect(stdout).to eq(base_help_message)
          expect(stderr).to include("you must add")
          expect(stderr).to include("chef shell-init")
        end

        it "passes when both are present in the correct order" do
          allow(cli).to receive(:env).and_return({ "PATH" => 'C:\opscode\chef-workstation\bin;C:\opscode\chef-workstation\embedded\bin' })
          allow(cli).to receive(:omnibus_embedded_bin_dir).and_return("c:/opscode/chef-workstation/embedded/bin")
          allow(cli).to receive(:omnibus_bin_dir).and_return("c:/opscode/chef-workstation/bin")
          run_cli_with_sanity_check(0)
          expect(stdout).to eq(base_help_message)
        end

        it "passes when only the omnibus bin dir is present" do
          allow(cli).to receive(:env).and_return({ "PATH" => 'C:\opscode\chef-workstation\bin' })
          allow(cli).to receive(:omnibus_embedded_bin_dir).and_return("c:/opscode/chef-workstation/embedded/bin")
          allow(cli).to receive(:omnibus_bin_dir).and_return("c:/opscode/chef-workstation/bin")
          run_cli_with_sanity_check(0)
          expect(stdout).to eq(base_help_message)
        end
      end
    end

    context "when not installed via omnibus" do

      before do
        allow(cli).to receive(:omnibus_install?).and_return false
      end
      let(:ruby_path) { "/Users/bog/.lots_o_rubies/2.1.2/bin/ruby" }
      let(:expected_root_path) { "/Users/bog/.lots_o_rubies" }

      before do
        allow(File).to receive(:exist?).with(expected_root_path).and_return(false)

        %i{
          omnibus_root
          omnibus_bin_dir
          omnibus_embedded_bin_dir
        }.each do |method_name|
          allow(cli).to receive(method_name).and_raise(ChefCLI::OmnibusInstallNotFound.new)
        end
      end

      it "skips the sanity check without error" do
        run_cli_with_sanity_check(0)
      end

    end
  end
end
