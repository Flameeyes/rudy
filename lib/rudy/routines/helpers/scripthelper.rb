require 'tempfile'

module Rudy; module Routines; 
  #--
  # TODO: Rename to ShellHelper
  #++
  module ScriptHelper
    include Rudy::Routines::HelperBase 
    extend self
    
    Rudy::Routines.add_helper :local,  self
    Rudy::Routines.add_helper :remote, self
    
    # NOTE: Only routines that don't use Routines.generic_routine_wrapper
    # will processes these routine keywords.
    Rudy::Routines.add_helper :before, self
    Rudy::Routines.add_helper :after,  self
    Rudy::Routines.add_helper :script, self
    Rudy::Routines.add_helper :before_local, self
    Rudy::Routines.add_helper :after_local,  self
    Rudy::Routines.add_helper :script_local, self
        
    def execute(type, batch, rset, lbox, option=nil, argv=nil)

      if type.to_s =~ /local/   
        batch = { lbox.user => batch } if batch.is_a?(Proc)
        execute_command(batch, lbox, option, argv)
        
      else
        batch = { rset.user => batch } if batch.is_a?(Proc)
        execute_command(batch, rset, option, argv)
      end
    end

    
  private  

    # * +timing+ is one of: after, before, after_local, before_local
    # * +routine+ a single routine hash (startup, shutdown, etc...)
    # * +sconf+ is a config hash from machines config (ignored if nil)
    # * +robj+ an instance of Rye::Set or Rye::Box 
    def execute_command(batch, robj, option=nil, argv=nil)
      
      # We need to explicitly add the rm command for rbox so we
      # can delete the script config file when we're done. This
      # adds the method to this instance of rbox only.
      # We give it a funny so we can delete it knowing we're not
      # deleting a method added somewhere else. 
      def robj.rudy_tmp_rm(*args); cmd('rm', args); end
      
      original_user = robj.user
      
      batch.each_pair do |user, proc|
        
        if user.to_s != robj.user
          begin
            ld "Switching user to: #{user} (was: #{robj.user})"
            
            robj.add_key user_keypairpath(user)
            robj.switch_user user
            robj.connect
          rescue Net::SSH::AuthenticationFailed, Net::SSH::HostKeyMismatch => ex  
            STDERR.puts "Error connecting: #{ex.message}".color(:red)
            STDERR.puts "Skipping user #{user}".color(:red)
            next
          end
        end
        
        begin
          
          ### EXECUTE THE COMMANDS BLOCK
          robj.batch(option, argv, &proc)
          
        rescue Rye::CommandError => ex
          print_response(ex)
          choice = Annoy.get_user_input('(S)kip  (R)etry  (A)bort: ') || ''
           if choice.match(/\AS/i)
             return
           elsif choice.match(/\AR/i)
             retry
           else
             exit 12
           end
        rescue Rye::CommandNotFound => ex
          STDERR.puts "  CommandNotFound: #{ex.message}".color(:red)
          STDERR.puts ex.backtrace if Rudy.debug?
          choice = Annoy.get_user_input('(S)kip  (R)etry  (A)bort: ') || ''
           if choice.match(/\AS/i)
             return
           elsif choice.match(/\AR/i)
             retry
           else
             exit 12
           end
        ensure
          robj.enable_safe_mode  # In case it was disabled
        end
        
        robj.cd # reset to home dir
      end
      
      # Return the borrowed robj instance to the user it was provided with
      robj.switch_user original_user
      
    end
  end
  
end;end