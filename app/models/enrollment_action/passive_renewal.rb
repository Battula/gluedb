module EnrollmentAction
  class PassiveRenewal < Base
    def self.qualifies?(chunk)
      return false if chunk.length > 1
      return false if chunk.first.is_termination?
      chunk.first.is_passive_renewal?
    end
  end
end
