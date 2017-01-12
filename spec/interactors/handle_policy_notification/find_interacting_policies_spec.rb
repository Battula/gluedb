require "rails_helper"

describe HandlePolicyNotification::FindInteractingPolicies, :dbclean => :after_each do
  describe ".call" do
    let(:member_detail_collection) { double }
    let(:employer_details) { double(found_employer: employer) }
    let(:employer) { double }
    let(:plan_details) { double(found_plan: plan) }
    let(:plan) { double(coverage_type: "health")}
    let(:member_details) { double(member_id: "some_id", begin_date: Date.today, end_date: Date.today + 2.weeks) }
    let(:interacting_policies) {[]}
    let(:person) { FactoryGirl.create(:person)}
    let(:policy) { FactoryGirl.create(:policy, broker: nil)}

    let(:interaction_context) {
      OpenStruct.new({
        member_detail_collection: member_detail_collection,
        employer_details: employer_details,
        policy_details: policy_details,
        plan_details: plan_details,
      })
    }

    subject { HandlePolicyNotification::FindInteractingPolicies.call(interaction_context) }

    before do
      allow(member_detail_collection).to receive(:detect).and_return(member_details)
      allow(Person).to receive(:where).with({"members.hbx_member_id" => member_details.member_id}).and_return([person])
      allow(person).to receive(:policies).and_return([policy])
      policy.enrollees.each{|e| e.update_attributes(coverage_start: Date.today + 1.week, coverage_end: Date.today + 3.weeks) }
    end

    context "individual policy" do
      let(:policy_details) { double(market: "individual") }

      it "should return the policy if they dates overlap" do
        expect(subject.interacting_policies).to eq [policy]
      end

      context "with different years" do
        let(:member_details) { double(member_id: "some_id", begin_date: Date.today + 1.year, end_date: Date.today + 1.year + 2.weeks) }

        it "should return an empty array if they dates overlap" do
          expect(subject.interacting_policies).to eq []
        end
      end
    end

    context "shop policy" do
      let(:policy_details) { double(market: "shop") }
      let(:policy) { FactoryGirl.create(:policy, broker: nil) }
      let(:employer) { instance_double("Employer", id: "employer_fein", plan_year_of: plan_year) }
      let(:plan_year) { instance_double("PlanYear", start_date: Date.today) }

      before do
        allow(policy).to receive(:employer).and_return(employer)
        policy.plan.update_attributes(market_type: "shop")
      end

      it "should return the policy if they dates overlap" do
        expect(subject.interacting_policies).to eq [policy]
      end

      context "with different years" do
        let(:member_details) { double(member_id: "some_id", begin_date: Date.today + 1.year, end_date: Date.today + 1.year + 2.weeks) }

        it "should return an empty array if they dates overlap" do
          expect(subject.interacting_policies).to eq []
        end
      end
    end
  end

  describe ".overlap_date_range" do
    subject { HandlePolicyNotification::FindInteractingPolicies.new.overlap_date_range(event_start,event_end,policy_start,policy_end,event_year,policy_year) }
    let(:start_date) { Date.today }
    let(:end_date) { start_date + 2.weeks }
    let(:policy_start) { start_date }
    let(:event_start) { start_date }
    let(:policy_end) { end_date }
    let(:event_end) { end_date }
    let(:event_year) { start_date.year }
    let(:policy_year) { start_date.year }

    context "no end dates" do
      let(:policy_end) { nil }
      let(:event_end) { nil }

      context "event years match" do
        it "overlaps" do
          expect(subject).to eq true
        end
      end

      context "event years don't match" do
        let(:policy_year) { policy_start.year + 1.year }

        it "does not overlap" do
          expect(subject).to eq false
        end
      end
    end

    context "same start dates" do
      it "overlaps" do
        expect(subject).to eq true
      end
    end

    context "event is before policy" do
      let(:event_start) { policy_start - 2.months }

      context "event has no end date" do
        let(:event_end) { nil }

        it "overlaps" do
          expect(subject).to eq true
        end
      end

      context "event ends before policy start" do
        let(:event_end) { policy_start - 1.week}

        it "does not overlap" do
          expect(subject).to eq false
        end
      end

      context "event ends after policy start" do
        let(:event_end) { policy_start + 1.week}

        it "overlaps" do
          expect(subject).to eq true
        end
      end
    end

    context "policy is before event" do
      let(:policy_start) { event_start - 2.months }

      context "policy has no end date" do
        let(:policy_end) { nil }

        it "overlaps" do
          expect(subject).to eq true
        end
      end

      context "policy ends before event start" do
        let(:policy_end) { event_start - 1.week}

        it "does not overlap" do
          expect(subject).to eq false
        end
      end

      context "policy ends after event start" do
        let(:policy_end) { event_start + 1.week}

        it "overlaps" do
          expect(subject).to eq true
        end
      end
    end

    context "event ends same day policy starts" do
      let(:event_end) { policy_start }

      it "overlaps" do
        expect(subject).to eq true
      end
    end

    context "policy ends same day event starts" do
      let(:policy_end) { event_start }

      it "overlaps" do
        expect(subject).to eq true
      end
    end
  end
end
