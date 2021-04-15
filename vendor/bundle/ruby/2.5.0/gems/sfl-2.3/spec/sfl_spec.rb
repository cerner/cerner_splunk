$: << File.dirname(__FILE__) + '/../lib'
require 'sfl'
require 'tempfile'

describe 'SFL.new' do
  context 'with argument "ls", "."' do
    subject { SFL.new('ls', '.') }
    it { should == SFL.new('ls', '.') }
    it { should == SFL.new(['ls', 'ls'], '.') }
    it { should_not == SFL.new('ls', 'aaaaa') }
    it { should == SFL.new({}, 'ls', '.') }
    it { should == SFL.new({}, 'ls', '.', {}) }
    it { should_not == SFL.new({1=>2}, 'ls', '.', {}) }
  end

  context 'with argument {"A" => "1"}, ["ls", "dir"]' do
    subject { SFL.new({"A" => "1"}, ['ls', 'dir']) }
    it { should == SFL.new({"A" => "1"}, ['ls', 'dir']) }
    it { should == SFL.new({"A" => "1"}, ['ls', 'dir'], {}) }
    it { should_not == SFL.new({"A" => "1"}, 'ls', 'dir', {}) }
    it { should_not == SFL.new(['ls', 'ls']) }
  end

  context 'with argument {"A" => "a"}, "ls", ".", {:out => :err}' do
    subject { SFL.new({"A" => "a"}, "ls", ".", {:out => :err}) }
    it { should == SFL.new({"A" => "a"}, ['ls', 'ls'], '.', {:out => :err}) }
  end

  context 'with argument "ls ."' do
    subject { SFL.new('ls .') }
    it { should == SFL.new('ls .') }
    it { should == SFL.new('ls', '.') }
    it { should == SFL.new(['ls', 'ls'], '.') }
  end
end

describe 'Kernel.spawn' do
  def mocker(code)
    sfl_expanded = File.expand_path('../../lib/sfl', __FILE__)
    rubyfile = File.expand_path(Dir.tmpdir, 'mocker.rb')
    File.open(rubyfile, 'w') {|io| io.puts <<-"EOF"
        require '#{sfl_expanded}'
      #{code}
      EOF
    }
    resultfile = File.expand_path(Dir.tmpdir, '../mocker_output.txt')
    system "ruby #{rubyfile} > #{resultfile}"
    File.read(resultfile)
  end

  context 'with command "ls", "."' do
    it 'outputs the result of "ls ." on stdout' do
      mocker(%q|
        pid = Kernel.spawn('ls', '.')
        Process.wait(pid)
        |).should == `ls .`
    end
  end

  context 'with command "echo ahi"' do
    it 'outputs "ahi" on stdout' do
      mocker(%q|
        pid = Kernel.spawn('echo ahi')
        Process.wait(pid)
        |).chomp.should == "ahi"
    end
  end

  context 'with command "true && echo ahi"' do
    it 'outputs "ahi" on stdout' do
      mocker(%q|
        pid = Kernel.spawn('true && echo ahi')
        Process.wait(pid)
        |).chomp.should == "ahi"
    end
  end

  context 'with command "false || :"' do
    it 'does not fail' do
      mocker(%q[
        pid = Kernel.spawn('false || :')
        Process.wait(pid)
        puts 'ahi' if $?.to_i == 0
        ]).chomp.should == "ahi"
    end
  end

  # The following test is unsound and lead to spec
  # failures under specific rubies...
  #
  # it 'is asynchronous' do
  #   mocker(%q|
  #     Kernel.spawn('sh', '-c', 'echo 1; sleep 1; echo 2')
  #     sleep 0.1
  #     |).should == "1\n"
  # end

  context 'with environment {"A" => "1"}' do
    it 'outputs with given ENV "1"' do
      mocker(%q|
        pid = Kernel.spawn({'A' => 'a'}, 'ruby', '-e', 'p ENV["A"]')
        Process.wait(pid)
        |).should == "a".inspect + "\n"
    end
  end

  context 'with option {:err => :out}' do
    it 'outputs with given ENV "1"' do
      mocker(
        %q|
        pid = Kernel.spawn('ls', 'nonexistfile', {:err => :out})
        Process.wait(pid)
        |).should =~ /^ls:/
    end
  end

  context 'with option {:out => "$TMPDIR/aaaaaaa.txt"}' do
    it 'outputs with given ENV "1"' do
      tmpfile_path = File.expand_path(Dir.tmpdir, "aaaaaaa.txt")
      mocker(
        %q|
        pid = Kernel.spawn('echo', '123', {:out => tmpfile_path})
        Process.wait(pid)
        |).should == ""
      File.read(tmpfile_path).should == "123\n"
    end
  end

  context 'with option {:out => :close, :err => :close}' do
    it 'outputs nothing at all' do
      mocker(
        %q|
        pid = Kernel.spawn('echo', '123', {:out => :close, :err => :close})
        Process.wait(pid)
        |).should == ""
    end
  end

  context 'with option {[:out, :err] => :close}' do
    it 'outputs nothing at all' do
      mocker(
        %q|
        pid = Kernel.spawn('echo', '123', {[:out, :err] => :close})
        Process.wait(pid)
        |).should == ""
    end
  end

  context 'with option {:in => "README.md"}' do
    it 'outputs README.md' do
      mocker(
        %q|
        pid = Kernel.spawn('cat', {:in => File.expand_path('../../README.md', __FILE__)})
        Process.wait(pid)
        |).should =~ /Spawn for Legacy/
    end
  end
end

describe 'SFL.option_parser' do
  it 'with symbol arguments' do
    SFL.option_parser({:err => :out}).
      should == [[STDERR, :reopen, STDOUT]]

    SFL.option_parser({:err => 'filename'}).
      should == [[STDERR, :reopen, [File, :open, 'filename', 'w']]]

    o = File.open('/dev/null', 'w')
    SFL.option_parser({:out => o}).
      should == [[STDOUT, :reopen, o]]

    SFL.option_parser({[:out, :err] => 'filename'}).
      should == [
        [STDOUT, :reopen, [File, :open, 'filename', 'w'] ],
        [STDERR, :reopen, STDOUT]
      ]

    SFL.option_parser({:chdir => 'aaa'}).
      should == [[Dir, :chdir, 'aaa']]

    SFL.option_parser({:err => :out, :chdir => 'aaa'}).
      should == [
        [Dir, :chdir, 'aaa'],
        [STDERR, :reopen, STDOUT]
      ]
  end
end

describe 'SFL.parse_command_with_arg' do
  context 'ls .' do
    subject { SFL.parse_command_with_arg('ls .') }
    it { should == ['ls', '.'] }
  end

  context 'ls " "' do
    subject { SFL.parse_command_with_arg('ls " "') }
    it { should == ['ls', ' '] }
  end
end

describe 'spawn()' do
  it 'exists' do
    Kernel.respond_to?(:spawn).should be_true
    Process.respond_to?(:spawn).should be_true
  end
  it 'is callable' do
    lambda{ Process.wait spawn("ruby -e 'true'") }.should_not raise_error
  end
end
