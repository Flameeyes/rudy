

module Rudy; module CLI; 
module AWS; module EC2;
  
  class KeyPairs < Rudy::CLI::Base
    
    def create_keypairs
      puts "Create KeyPairs".bright
      rkey = Rudy::KeyPairs.new
      name = @argv.kpname
      
      rkey.create(@argv.kpname, :force => false)
      rkey.list.each do |kp|
        puts kp.to_s
      end
    end
    
    
    def destroy_keypairs
      puts "Destroy KeyPairs".bright
      rkey = Rudy::KeyPairs.new
      raise "KeyPair #{rkey.name(@argv.kpname)} does not exist" unless rkey.exists?(@argv.kpname)
      kp = rkey.get(@argv.kpname)
      puts "Destroying keypair: #{kp.name}"
      puts "NOTE: the private key file will also be deleted and you will not be able to".color(:blue)
      puts "connect to instances started with this keypair.".color(:blue)
      exit unless Annoy.are_you_sure?(:low)
      ret = rkey.destroy(@argv.kpname)
      puts ret ? "Success" : "Failed"
    end
    
    def keypairs
      puts "KeyPairs".bright
      rkey = Rudy::KeyPairs.new
      
      rkey.list.each do |kp|
        puts kp.to_s
      end
      
      puts "No keypairs" unless rkey.any?
      
    end
    
    
  end


end; end
end; end