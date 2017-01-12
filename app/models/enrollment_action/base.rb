module EnrollmentAction
  class Base
    attr_reader :action
    attr_reader :termination

    def initialize(term, init)
      @termination = term
      @action = init
    end


    def self.select_action_for(chunk)
      [
        ::EnrollmentAction::PassiveRenewal,
        ::EnrollmentAction::ActiveRenewal,
        ::EnrollmentAction::CarrierSwitch,
        ::EnrollmentAction::CarrierSwitchRenewal,
        ::EnrollmentAction::DependentAdd,
        ::EnrollmentAction::DependentDrop,
        ::EnrollmentAction::InitialEnrollment,
        ::EnrollmentAction::PlanChange,
        ::EnrollmentAction::PlanChangeDependentAdd,
        ::EnrollmentAction::PlanChangeDependentDrop,
        ::EnrollmentAction::RenewalDependentAdd,
        ::EnrollmentAction::RenewalDependentDrop
      ].detect { |kls| kls.qualifies?(chunk) }.construct(chunk)
    end

    def self.construct(chunk)
      term = chun.detect { chunk.is_termination? }
      action = chun.detect { !chunk.is_termination? }
      self.class.new(term, init)
    end
      
  end
end
