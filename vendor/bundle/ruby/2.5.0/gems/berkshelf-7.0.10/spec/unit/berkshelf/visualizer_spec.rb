require "rspec"
require "spec_helper"

module Berkshelf
  describe Visualizer, :not_supported_on_windows do
    describe "#to_png" do
      context "when graphviz is not installed" do
        before do
          allow(Berkshelf).to receive(:which)
            .with("dot")
            .and_return(nil)
          allow(Berkshelf).to receive(:which)
            .with("dot.exe")
            .and_return(nil)
        end

        it "raises a GraphvizNotInstalled exception" do
          expect { subject.to_png }.to raise_error(GraphvizNotInstalled)
        end
      end

      context "when the graphviz command fails", :graphviz do
        before do
          response = double(error?: true, stderr: "Something happened!")
          allow(subject).to receive(:shell_out).and_return(response)
        end

        it "raises a GraphvizCommandFailed exception" do
          expect { subject.to_png }.to raise_error(GraphvizCommandFailed)
        end
      end

      context "when the graphviz command succeeds", :graphviz do
        it "builds a dot from a Lockfile" do
          outfile = tmp_path.join("test-graph.dot").to_s
          lockfile = Lockfile.from_file(fixtures_path.join("lockfiles/default.lock").to_s)

          Visualizer.from_lockfile(lockfile).to_dot_file(outfile)

          expect(File.exist?(outfile)).to be true
        end

        it "builds a png from a Lockfile" do
          outfile = tmp_path.join("test-graph.png").to_s
          lockfile = Lockfile.from_file(fixtures_path.join("lockfiles/default.lock").to_s)

          Visualizer.from_lockfile(lockfile).to_png(outfile)

          expect(File.exist?(outfile)).to be true
        end
      end
    end
  end
end
