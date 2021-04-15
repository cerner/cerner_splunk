require "mixlib/authentication/digester"

describe Mixlib::Authentication::Digester do
  context "backcompat" do
    # The digester API should really have been private,
    # however oc-chef-pedant uses it.
    let(:test_string) { "hello" }
    let(:test_string_checksum) { "qvTGHdzF6KLavt4PO0gs2a6pQ00=" }

    describe "#hash_file" do
      it "should default to use SHA1" do
        expect(described_class.hash_file(StringIO.new(test_string))).to(
          eq(test_string_checksum))
      end
    end

    describe "#hash_string" do
      it "should default to use SHA1" do
        expect(described_class.hash_string(test_string)).to(
          eq(test_string_checksum))
      end
    end
  end
end
