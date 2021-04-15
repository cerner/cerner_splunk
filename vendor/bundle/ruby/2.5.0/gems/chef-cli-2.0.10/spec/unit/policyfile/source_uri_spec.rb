#
# Copyright:: Copyright (c) 2016 Chef Software Inc.
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

require "chef-cli/policyfile/source_uri"

describe ChefCLI::Policyfile::SourceURI do
  subject { described_class.parse(source_uri) }

  describe "#validate" do
    context "when the scheme is not https" do
      let(:source_uri) { "ftp://chef.example.com" }

      it "raises ChefCLI::InvalidPolicyfileSourceURI" do
        expect do
          subject.validate
        end.to raise_error(ChefCLI::InvalidPolicyfileSourceURI)
      end
    end
  end
end
