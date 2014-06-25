require 'spec_helper'

describe Validators::PremiumValidator do
  let(:enrollment_group) { double }
  let(:plan) { double }
  let(:listener) { double }
  let(:validator) { Validators::PremiumValidator.new(enrollment_group, plan, listener) }

  context 'premium does not match plan premium' do
    before do
      plan.stub(:premium_for_enrollee) { double(amount: 22.0) }

      enrollment_group.stub(:enrollees) do
        [ double(premium_amount: 666.66, name: 'Name') ]
      end
    end
    it 'notifies the listener' do
      expect(listener).to receive(:enrollee_has_incorrect_premium).with({name: 'Name', provided: 666.66, expected: 22.0})
      expect(validator.validate).to eq false
    end
  end

  context 'premium matches plan premium' do
    before do
      plan.stub(:premium_for_enrollee) { double(amount: 22.0) }
      enrollment_group.stub(:enrollees) do
        [ double(premium_amount: 22.0, name: 'Name') ]
      end
    end
    it 'does not notify the listener' do
      expect(listener).not_to receive(:enrollee_has_incorrect_premium)
      expect(validator.validate).to eq true
    end
  end

  context 'when there are >5 enrollees' do
    before do
      enrollees = []
      5.times { enrollees << double(age: 40, premium_amount: 22.0) }
      enrollees << youngest

      plan.stub(:premium_for_enrollee) { double(amount: 22.0) }
      enrollment_group.stub(:enrollees) { enrollees }
    end 

    context 'and youngest isnt free' do
      let(:youngest) { double(age: 1, premium_amount: 22.0, name: 'Name') }
      it 'notifies listener that the premium is incorrect' do
        expect(listener).to receive(:enrollee_has_incorrect_premium).with({name: 'Name', provided: 22.0, expected: 0})
        expect(validator.validate).to eq false
      end
    end

    context 'and youngest is free' do
      let(:youngest) { double(age: 1, premium_amount: 0.0, name: 'Name') }
      it 'does NOT notifies listener that the premium is incorrect' do
        expect(listener).not_to receive(:enrollee_has_incorrect_premium)
        expect(validator.validate).to eq true
      end
    end
  end
end