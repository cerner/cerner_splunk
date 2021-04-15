#
# Copyright:: Copyright (c) 2015 Chef Software Inc.
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
require "yaml"
require "chef-cli/command/env"

describe ChefCLI::Command::Env do
  let(:ui) { TestHelpers::TestUI.new }
  let(:command_instance) { ChefCLI::Command::Env.new }

  let(:command_options) { [] }

  let(:user_bin_dir) { File.expand_path(File.join(Gem.user_dir, "bin")) }
  let(:omnibus_embedded_bin_dir) { "/foo/embedded/bin" }
  let(:omnibus_bin_dir) { "/foo/bin" }

  it "has a usage banner" do
    expect(command_instance.banner).to eq("Usage: chef env")
  end

  describe "when running from within an omnibus install" do
    before do
      allow(command_instance).to receive(:omnibus_install?).and_return true
      allow(command_instance).to receive(:omnibus_embedded_bin_dir).and_return(omnibus_embedded_bin_dir)
      allow(command_instance).to receive(:omnibus_bin_dir).and_return(omnibus_bin_dir)
      command_instance.ui = ui
    end

    describe "and the env command is run" do
      let(:yaml) { YAML.load(ui.output) }
      before :each do
        run_command
      end
      it "output should be valid yaml" do
        expect { yaml }.not_to raise_error
      end
      it "should include correct Workstation version info" do
        expect(yaml).to have_key ChefCLI::Dist::PRODUCT
        expect(yaml[ChefCLI::Dist::PRODUCT]["Version"]).to eql ChefCLI::VERSION
      end
    end
  end
  describe "when running locally" do
    before do
      allow(command_instance).to receive(:omnibus_install?).and_return false
      command_instance.ui = ui
    end

    describe "and the env command is run" do
      let(:yaml) { YAML.load(ui.output) }
      before :each do
        run_command
      end
      it "output should be valid yaml" do
        expect { yaml }.not_to raise_error
      end
      it "Workstation version should indicate that that we're not runnign from a WS install" do
        expect(yaml).to have_key ChefCLI::Dist::PRODUCT
        expect(yaml[ChefCLI::Dist::PRODUCT]["Version"]).to eql "Not running from within Workstation"
      end
      it "should return valid yaml" do
        run_command
        expect { YAML.load(ui.output) }.not_to raise_error
      end
    end
  end
  def run_command
    command_instance.run_with_default_options(false, command_options)
  end

end
