module EnrollmentAction
  class PlanChangeDependentDrop < Base
    def self.qualifies?(chunk)
      return false if chunk.length < 2
      return false if same_plan?(chunk)
      (!carriers_are_different?(chunk)) && dependents_dropped?(chunk)
    end

    def self.same_plan?(chunk)
    end

    def self.dependents_dropped?(chunk)
    end

    def self.carriers_are_different?(chunk)
    end
  end
end
