module MPV

  class Base

    def self.finalize(method, ptr)
      proc {
        MPV.send(method, ptr) unless ptr == 0
      }
    end

    def define_finalizer(method, ptr)
      ObjectSpace.define_finalizer(self, self.class.finalize(method, ptr))
    end

  end

end