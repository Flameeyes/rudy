

module Rudy
  class Domains
    include Rudy::Huxtable
    
    
    def list
      @@sdb.domains.list || []
    end
    
    def get(n=nil)
      n = name(Rudy::RUDY_DOMAIN)
      n &&= n.to_s
      doms = list.select { |domain| domain == n }
      doms = nil if doms.empty?
      doms
    end
    
    def exists?(n=nil)
      !get(n).nil?
    end
    
    def name(n=nil)
      n || Rudy::RUDY_DOMAIN
    end
    
    def create(n=nil)
      n = name(n)
      @@sdb.domains.create(n)
    end
      
  end
end