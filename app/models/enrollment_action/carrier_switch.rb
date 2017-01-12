module EnrollmentAction
  class CarrierSwitch < Base
    def self.qualifies?(chunk)
      return false unless chunk.length > 1
      carriers_are_different?(chunk)
    end

    def self.carriers_are_different?(chunk)
    end
  end
end
