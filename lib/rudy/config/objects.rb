

class Rudy::Config
  class Error < Rudy::Error
    def initialize(ctype, obj)
      @ctype, @obj = ctype, obj
    end
    def message; "Error in #{@ctype}: #{@obj}"; end
  end
  class Machines < Caesars; end
  class Defaults < Caesars; end
  class Networks < Caesars; end
  class Controls < Caesars; end
  class Services < Caesars; end
  # Modify the SSH command available in routines. The default
  # set of commands is defined by Rye::Cmd (Rudy executes all
  # SSH commands via Rye). 
  #
  # NOTE: We allow people to define their own keywords. It is
  # important that new keywords do not conflict with existing
  # Rudy keywords. Strange things may happen!
  class Commands < Caesars
    class PathNotString < Rudy::Config::Error
      def message; super << " (path must be a String)"; end
    end
    class ReservedKeyword < Rudy::Config::Error
      def message; super << " (r)"; end
    end
    class BadArg < Rudy::Config::Error
      def message; "Arguments for #{cmd} must be: Symbols, Strings only"; end
    end
      
    @@processed = false
    forced_array :allow
    forced_array :deny
    def init
      # We can't process the Rye::Cmd commands here because the
      # DSL hasn't been parsed yet so Rudy::Config.postprocess
      # called the following postprocess method after parsing.
    end
    # Process the directives specified in the commands config.
    # NOTE: This affects the processing of the routines config
    # which only works if commands is parsed first. This works
    # naturally if each config has its own file b/c Rudy loads
    # files via a glob (globs are alphabetized and "commands"
    # comes before "routines"). 
    #
    # That's obviously not good enough but for now commands
    # configuration MUST be put before routines. 
    def postprocess
      return false if @@processed
      @@processed = true  # Make sure this runs only once
      # Parses:
      # commands do
      #   allow :kill 
      #   allow :custom_script, '/full/path/2/custom_script'
      #   allow :git_clone, "/usr/bin/git", "clone"
      # end
      # 
      # * Tells Routines to force_array on the command name.
      # This is important b/c of the way we parse commands 
      self.allow.each do |cmd|
        cmd, path, *args = *cmd
        
        # If no path was specified, we can assume cmd is in the remote path so
        # when we add the method to Rye::Cmd, we'll it the path is "cmd".
        path ||= cmd.to_s
        
        # We cannot allow new commands to be defined that conflict use known
        # routines keywords. This is based on keywords in the current config.
        # NOTE: We can't check for this right now b/c the routines config
        # won't necessarily have been parsed yet. TODO: Figure it out!
        #if Caesars.known_symbol_by_glass?(:routines, cmd)
        #  raise ReservedKeyword.new(:commands, cmd)
        #end
        
        # The second argument must be a filesystem path
        raise PathNotString.new(:commands, cmd) if path && !path.is_a?(String)
        
        # We can allow existing commands to be overridden but we
        # print a message to STDERR so the user knows what's up.
        STDERR.puts "Redefined #{cmd}" if Rye::Cmd.can?(cmd)
        
        # Insert hardcoded arguments if any were supplied. These will
        # be sent automatically with every call to the new command.
        # This loop prepares the hardcoded args to be passed to eval.
        args.collect! do |arg| 
          klass = [Symbol, String] & [arg.class]
          raise BadArg.new(:commands, cmd) if klass.empty?
          # Symbols sent as Symbols, Strings as Strings
          arg.is_a?(Symbol) ? ":#{arg}" : "'#{arg}'"
        end
        hard_args = args.empty? ? "*args" : "#{args.join(', ')}, *args"
        
        # Command keywords must be parsed with forced_array. See ScriptHelper.
        Rudy::Config::Routines.forced_array cmd
        Rye::Cmd.module_eval %Q{
          def #{cmd}(*args); cmd(:'#{path}', #{hard_args}); end
        }
      end
      # We deny commands by telling routines to not parse the given keywords
      self.deny.each do |cmd|
        Rudy::Config::Routines.forced_ignore cmd.first # cmd is a forced array
        # We don't remove the method from Rye:Cmd because we 
        # may need elsewhere in Rudy. Forced ignore ensures
        # the config is not stored anyhow.
      end
      raise Caesars::Config::ForceRefresh.new(:routines)
    end
  end
  
  class Accounts < Caesars
    def valid?
      (!aws.nil? && !aws.accesskey.nil? && !aws.secretkey.nil?) &&
      (!aws.account.empty? && !aws.accesskey.empty? && !aws.secretkey.empty?)
    end
  end
  
  class Routines < Caesars
    
    # Disk routines
    forced_hash :create
    forced_hash :destroy
    forced_hash :restore
    forced_hash :mount
    
    # Remote scripts
    forced_hash :before
    forced_hash :before_local
    forced_hash :after
    forced_hash :after_local
    
    # Version control systems
    forced_hash :git
    forced_hash :svn
    
    def init
      
    end
    
    # Add remote shell commands to the DSL as forced Arrays. 
    # Example:
    #     ls :a, :l, "/tmp"  # => :ls => [[:a, :l, "/tmp"]]
    #     ls :o              # => :ls => [[:a, :l, "/tmp"], [:o]]
    # NOTE: Beware of namespace conflicts in other areas of the DSL,
    # specifically shell commands that have the same name as a keyword
    # we want to use in the DSL. This includes commands that were added
    # to Rye::Cmd before Rudy is 'require'd. 
    Rye::Cmd.instance_methods.sort.each do |cmd|
      forced_array cmd
    end
    
  end
end