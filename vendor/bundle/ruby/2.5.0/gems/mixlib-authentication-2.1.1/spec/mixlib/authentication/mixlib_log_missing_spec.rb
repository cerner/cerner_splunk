describe "Mixlib::Authentication::Log" do
  before do
    Mixlib::Authentication.send(:remove_const, "DEFAULT_SERVER_API_VERSION")
    Mixlib::Authentication.send(:remove_const, "Log")
  end

  context "without mixlib-log" do
    before do
      @mixlib_path = $LOAD_PATH.find { |p| p.match("mixlib-log") }
      $LOAD_PATH.reject! { |p| p.match("mixlib-log") }

      load "mixlib/authentication.rb"
    end

    after do
      $LOAD_PATH.unshift(@mixlib_path)
    end

    it "uses MixlibLogMissing" do
      expect(Mixlib::Authentication::Log.singleton_class.included_modules)
        .to include(Mixlib::Authentication::NullLogger)
    end

    it "default log level is :error" do
      expect(Mixlib::Authentication::Log.level).to eq(:error)
    end

    %w{trace debug info warn error fatal}.each do |level|
      it "logs at level #{level}" do
        expect(Mixlib::Authentication::Log).to receive(level).with("foo")

        Mixlib::Authentication.logger.send(level, "foo")
      end
    end
  end

  context "with mixlib-log" do
    before do
      load "mixlib/authentication.rb"
    end

    it "uses Mixlib::Log" do
      expect(Mixlib::Authentication::Log.singleton_class.included_modules)
        .to include(Mixlib::Log)
    end

    %w{trace debug info warn error fatal}.each do |level|
      it "forward #{level} to mixlib-log" do
        expect_any_instance_of(Mixlib::Log).to receive(level).with("foo")

        Mixlib::Authentication.logger.send(level, "foo")
      end
    end
  end
end
