require File.join(Rails.root, "app", "models", "premiums", "quote_cv_proxy.rb")

class Api::V2::QuoteGeneratorController < ApplicationController
  skip_before_filter :authenticate_user_from_token!
  skip_before_filter :authenticate_me!
  skip_before_filter :verify_authenticity_token

  def generate

    begin
      quote_request_xml = request.body.read

      quote_validator = QuoteValidator.new(quote_request_xml)
      quote_validator.check_against_schema

      if !quote_validator.valid?
        raise quote_validator.errors.to_xml
      end

      xml_node = Nokogiri::XML(quote_request_xml)

      plan_hash = Parsers::Xml::Cv::PlanParser.parse(xml_node).first.to_hash
      quote_cv_proxy = QuoteCvProxy.new(quote_request_xml)

      enrollees, member_cache_hash = quote_cv_proxy.enrollees
      member_cache = Caches::CustomCache.new(member_cache_hash)

      plan = quote_cv_proxy.plan

      if quote_cv_proxy.invalid?
        errors = ""
        quote_cv_proxy.errors.each do |attribute, error| errors += "<error>#{attribute} #{error}</error>" end
        raise errors
      end

      policy = Policy.new(plan: plan, enrollees: enrollees)

      premium_calculator = Premiums::PolicyCalculator.new(member_cache)
      premium_calculator.apply_calculations(policy)

      quote_cv_proxy.enrollees_pre_amt=policy.enrollees
      quote_cv_proxy.policy_pre_amt_tot=policy.pre_amt_tot
      quote_cv_proxy.ehb=policy.plan.ehb*100

      render :xml => quote_cv_proxy.response_xml, :status => :ok
    rescue Exception => e
      render :xml => "<errors>#{e.message}</errors>", :status => :unprocessable_entity
    end

  end
end
