module EnrollmentAction
  class Termination < Base
    def self.qualifies?(chunk)
      return false if chunk.length > 1
      chunk.first.is_termination?
    end
  end
end
