module EnrollmentAction
  class DependentDrop < Base
    def self.qualifies?(chunk)
      return false if chunk.length < 2
      return false unless same_plan?(chunk)
      dependents_dropped?(chunk)
    end

    def self.same_plan?(chunk)
    end

    def self.dependents_dropped?(chunk)
    end
  end
end
