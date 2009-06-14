
module Rudy; module Routines; 
  module UserHelper
    include Rudy::Routines::HelperBase  # TODO: use trap_rbox_errors
    extend self 
    
    Rudy::Routines.add_helper :adduser, self
    Rudy::Routines.add_helper :authorize, self
    
    def execute(type, user, rset, lbox, option=nil, argv=nil)
      send(type, user, rset)
    end
    
    def adduser(user, robj)
      
      # On Solaris, the user's home directory needs to be specified
      # explicitly so we do it for linux too for fun. 
      homedir = robj.guess_user_home(user.to_s)
      args = [:m, :d, homedir, :s, '/bin/bash', user.to_s]
      
      # NOTE: We'll may to use platform specific code here. 
      # Linux has adduser and useradd commands:
      # adduser can prompt for info which we don't want. 
      # useradd does not prompt (on Debian/Ubuntu at least). 
      # We need to specify bash b/c the default is /bin/sh
      robj.useradd(args)
    end
    
    def authorize(user, robj)
      robj.authorize_keys_remote(user.to_s)
    end
    
    
  end
  
end; end  