module EnrollmentAction
  class CarrierSwitchRenewal < Base
    def self.qualifies?(chunk)
      return false if chunk.length > 1
      return false if chunk.first.is_termination?
      return false if chunk.first.is_passive_renewal?
      has_other_carrier_renewal_candidate?(chunk.first) && !dependents_changed?(chunk.first)
    end

    def self.has_other_carrier_renewal_candidate?(enrollment_event)
    end

    def self.dependents_changed?(enrollment_event)
    end
  end
end
