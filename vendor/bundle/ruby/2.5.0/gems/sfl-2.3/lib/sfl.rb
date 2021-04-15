class SFL
  VERSION = "2.3".freeze

  SHELL_SPECIALS = %r([\*\?\{\}\[\]<>\(\)~&\|\\\$;'`"\n])m.freeze

  attr_reader :command, :environment, :argument, :option

  # SFL.new('ls', '-a') becomes
  #   @environment = {}
  #   @command = ['ls', 'ls']
  #   @argument = ['-a']
  #   @option = {}
  def initialize(*cmdandarg)
    raise ArgumentError if cmdandarg.size == 0
    cmdandarg = cmdandarg.dup

    @environment =
      if Hash === cmdandarg.first
        cmdandarg.shift
      else
        {}
      end

    @option =
      if Hash === cmdandarg.last
        cmdandarg.pop
      else
        {}
      end

    if cmdandarg.size == 1
      cmdandarg = cmdandarg.first
      if String === cmdandarg
        if SHELL_SPECIALS === cmdandarg
          @command = cmdandarg
          @argument = []
        else
          cmd, *arg = self.class.parse_command_with_arg(cmdandarg)
          @command = [cmd, cmd]
          @argument = arg
        end
      else
        @command = cmdandarg
        @argument = []
      end
    else
      # 'ls', '.' -> [['ls', 'ls'], '.']
      cmd = cmdandarg.shift
      cmd = (String === cmd) ? [cmd, cmd] : cmd
      @command = cmd
      @argument = cmdandarg
    end
  end

  def run
    fork {
      @environment.each do |k, v|
        ENV[k] = v
      end
      self.class.option_parser(@option).each do |ast|
        self.class.eval_ast ast
      end
      exec(@command, *@argument)
    }
  end

  def ==(o) # Mostly for rspec
    instance_variables.all? do |i|
      i = i[1..-1] # '@a' -> 'a'
      eval "self.#{i} == o.#{i}"
    end
  end

  class << self
    REDIRECTION_MAPPING = {
      :in  => STDIN,
      :out => STDOUT,
      :err => STDERR,
    }

    def redirection_ast(v, what_for = :out)
      case v
      when Integer
        raise NotImplementedError, "Redirection to integer FD not yet implemented"
      when :close
        nil
      when :in, :out, :err
        REDIRECTION_MAPPING[v]
      when String # filename
        [File, :open, v, (what_for == :in ? 'r' : 'w')]
      when Array # filename with option
        [File, :open, v[0], v[1]]
      when IO
        v
      end
    end

    def option_parser(hash)
      result = []

      # changing dir has high priority
      chdir = hash.delete(:chdir)
      if chdir
        result[0] = [Dir, :chdir, chdir]
      end

      # other options 
      result += hash.map {|k, v|
        case k
        when :in, :out, :err
          if right = redirection_ast(v, k)
            [[REDIRECTION_MAPPING[k], :reopen, right]]    
          else
            [[REDIRECTION_MAPPING[k], :close]]    
          end
        when Array
          # assuming k is like [:out, :err]
          raise NotImplementedError if k.size > 2
          left1, left2 = *k.map {|i| REDIRECTION_MAPPING[i] }
          if right = redirection_ast(v)
            [
              [left1, :reopen, right],
              [left2, :reopen, left1],
            ]
          else
            [
              [left1, :close],
              [left2, :close],
            ]
          end
        end
      }.flatten(1)
      result
    end

    def eval_ast(ast)
      case ast
      when Array
        if ast.size > 2
          eval_ast(ast[0]).send(ast[1], *ast[2..-1].map {|i| eval_ast(i) })
        else
          eval_ast(ast[0]).send(ast[1])
        end
      else
        ast
      end
    end

    def parse_command_with_arg(x)
      in_squote = false
      in_dquote = false
      tmp = ''
      cmdargs = []
      x.strip.split(//).each do |c|
        case c
        when '"'
          if in_dquote
            in_dquote = false
          else
            in_dquote = true
          end
        when "'"
          if in_squote
            in_squote = false
          else
            in_squote = true
          end
        when ' '
          if in_dquote || in_squote
            tmp << ' '
          else
            cmdargs << tmp
            tmp = ''
          end
        else
          tmp << c
        end
      end
      cmdargs << tmp
    end
  end
end

if RUBY_VERSION < "1.9"
  def Kernel.spawn(*x)
    SFL.new(*x).run
  end

  def spawn(*x)
    Kernel.spawn(*x)
  end

  def Process.spawn(*x)
    SFL.new(*x).run
  end
end

if RUBY_VERSION <= '1.8.6'
  class Array
    alias orig_flatten flatten

    def flatten(depth = -1)
      if depth < 0
        orig_flatten
      elsif depth == 0
        self
      else
        inject([]) {|m, i|
          Array === i ? m + i : m << i
        }.flatten(depth - 1)
      end
    end
  end
end
