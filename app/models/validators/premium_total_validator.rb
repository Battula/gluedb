module Validators

  class PremiumTotalValidator
    def initialize(enrollment_group, listener)
      @enrollment_group = enrollment_group
      @listener = listener
    end

    def validate
      provided = @enrollment_group.premium_amount_total
      expected = @enrollment_group.enrollee_premium_sum

      if(provided != expected)
        @listener.group_has_incorrect_premium_total({provided: provided, expected: expected})
        return false
      end
      true
    end
  end
end