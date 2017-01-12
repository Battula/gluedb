module EnrollmentAction
  class RenewalDependentDrop < Base
    def self.qualifies?(chunk)
      return false if chunk.length > 1
      return false if chunk.first.is_termination?
      return false if chunk.first.is_passive_renewal?
      has_same_carrier_renewal_candidates?(chunk.first) && dependents_dropped?(chunk.first)
    end

    def self.dependents_dropped?(enrollment_event)
    end

    def self.has_same_carrier_renewal_candidates?(enrollment_event)
    end
  end
end
