module EnrollmentAction
  class DependentAdd < Base
    def self.qualifies?(chunk)
      return false if chunk.length < 2
      return false unless same_plan?(chunk)
      dependents_added?(chunk)
    end

    def self.dependents_added?(chunk)
    end

    def self.same_plan?(chunk)
    end
  end
end
