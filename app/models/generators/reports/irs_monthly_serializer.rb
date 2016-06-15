require 'spreadsheet'
require 'csv'
module Generators::Reports  
  class IrsMonthlySerializer

    CALENDER_YEAR = 2016

    def initialize
      @logger = Logger.new("#{Rails.root}/log/h36_exceptions.log")

      @carriers = Carrier.all.inject({}){|hash, carrier| hash[carrier.id] = carrier.name; hash}
      puts @carriers.inspect
      
      @policy_family_hash = {}

      @h36_root_folder = "#{Rails.root}/irs/h36_#{Time.now.strftime('%m_%d_%Y_%H_%M')}"
      create_directory @h36_root_folder
    end

    def process    
      count = 0
      current = 0
      folder_count = 1

      # missing_irs_groups = []
      # multiple_taxhouseholds = []

      create_directory("#{@h36_root_folder}/transmission")
      create_new_irs_folder(folder_count)

      # non_auth_families = 0
      # non_auth_pols = 0
      # families_with_no_coverage = 0
      # missing_active_enrollments = 0

      book = Spreadsheet.open "#{Rails.root}/EXCLUSION_2015_H41_EOY_201602111545.xls"
      skip_list = book.worksheets.first.inject([]){|data, row| data << row[0].to_s.strip.to_i}.compact

      start = Time.now
      Family.all.each do |family|

      # [52428, 52918, 55598, 53303, 55584, 55577].inject([]){|families, policy_id|
      #   families << Family.where("family_members.person_id" => Moped::BSON::ObjectId.from_string(Policy.find(policy_id).subscriber.person.id)).first
      # }.each do |family|

        # puts family.e_case_id.inspect

        current += 1

        if current % 100 == 0
          puts "currently at #{current}"
        end

        begin
          if family.households.count > 1 || family.active_household.nil? 
            next
          end

          # if family.primary_applicant.nil?
          #   puts "------------found more than one household/activehousehold nil/primary aplicant nil---#{family.e_case_id}"
          # end

          # next unless family.active_household.has_aptc?(CALENDER_YEAR)

          active_enrollments = family.active_household.enrollments_for_year(CALENDER_YEAR)
          if active_enrollments.compact.empty?
            # puts "-----#{family.e_case_id}"
            # missing_active_enrollments += 1
            next
          end

          active_pols = active_enrollments.map(&:policy)
          if active_pols.detect{|x| skip_list.include?(x.id) }
            next
          end

          if family.irs_groups.empty?
            # missing_irs_groups << family.e_case_id
            # puts "e_case_id --------- #{family.e_case_id}"
            next
          end

          # next unless family.active_household.tax_households.size == 0

          # non_authority_pols = active_enrollments.count { |enrollment| !enrollment.policy.belong_to_authority_member? }
          # if non_authority_pols > 0
          #   non_auth_pols += non_authority_pols
          #   non_auth_families += 1
          #   if non_authority_pols == active_enrollments.count
          #     families_with_no_coverage += 1
          #   end
          # end

          # build_policy_family_hash(active_pols, family)
          # active_pols = nil

          count += 1

          # next if active_enrollments.map(&:policy).any? {|pol| multi_version_aptc?(pol) }
          # policy_ids = active_enrollments.map(&:policy_id)
          # next if (policy_ids & policies_to_skip).any?

          active_enrollments = nil

          if family.family_members.any? {|x| x.person.authority_member.ssn == '999999999' }
            # puts "ssn with all 9's --- #{family.e_case_id.inspect}"
            next
          end

          if family.active_household.tax_households.count > 1
            # multiple_taxhouseholds << family.e_case_id
            # puts "---multiple tax households present"
          elsif family.active_household.tax_households.count == 0
            # puts "-----no tax household----#{family.e_case_id}"
          end

          # family.active_household.tax_households.each do |th|
          #   th.primary
          #   th.spouse
          #   th.dependents
          # end

          irs_group = build_irs_group(family)

          if irs_group.insurance_policies.empty?
            # puts "insurance policies empty --- #{family.e_case_id.inspect}"
            next
          end

          if irs_group.insurance_policies.any?{|policy| policy.no_coverage? || policy.no_premium_amount? }
            # puts "family has wrong policy --- #{family.e_case_id.inspect}"
            next
          end

          # if irs_group.households[0].tax_households.empty?
          #   puts "EMPTY TAX HOUSEHOLDS #{family.e_case_id}"
          #   next
          # end

          # if irs_group.households[0].tax_households[0].primary.blank?
          #   puts "EMPTY TAX PRIMARY #{family.e_case_id}"
          #   next
          # end


          # puts irs_group.policies.inspect

          group_xml = IrsMonthlyXml.new(irs_group, family.e_case_id)
          group_xml.folder_path = "#{@h36_root_folder}/#{@h36_folder_name}"
          group_xml.serialize

          irs_group = nil
          group_xml = nil

          if count % 3000 == 0
            merge_and_validate_xmls(folder_count)
            folder_count += 1
            create_new_irs_folder(folder_count)
          end

          if count % 100 == 0
            puts "so far --- #{count} --- out of #{current}"
            puts "time taken for current record ---- #{Time.now - start} seconds"
            start = Time.now
          end

        rescue Exception => e
          puts "Failed #{family.e_case_id}--#{e.to_s}"
        end
      end

      # print_families_with_samepolicy

      merge_and_validate_xmls(folder_count)
      create_manifest


      puts count
      # puts multiple

      # puts missing_irs_groups.inspect
      # puts missing_irs_groups.count

      # puts multiple_taxhouseholds.count
      # puts multiple_taxhouseholds.inspect

      # puts non_auth_families
      # puts non_auth_pols
      # puts families_with_no_coverage
      # puts missing_active_enrollments
    end

    def build_irs_group(family)
      builder = Generators::Reports::IrsGroupBuilder.new(family)
      builder.carrier_hash = @carriers
      builder.calender_year = CALENDER_YEAR
      builder.process
      builder.irs_group
    end

    def print_families_with_samepolicy
      @policy_family_hash.each do |policy_id, ecases|
        if ecases.count > 1
          puts "#{policy_id}---#{ecases.join(',').inspect}"
        end
      end   
    end

    def build_policy_family_hash(active_pols, family)
      active_pols.each do |pol|
        if @policy_family_hash.has_key?(pol.id)
          @policy_family_hash[pol.id] = @policy_family_hash[pol.id] + [family.e_case_id]
        else
          @policy_family_hash[pol.id] = [family.e_case_id]
        end
      end
    end

    def merge_and_validate_xmls(folder_count)
      folder_num = prepend_zeros(folder_count.to_s, 5)
      xml_merge = Generators::Reports::IrsXmlMerger.new("#{@h36_root_folder}/#{@h36_folder_name}", folder_num)
      xml_merge.irs_monthly_folder = @h36_root_folder
      xml_merge.process
      xml_merge.validate
    end

    def create_manifest
      Generators::Reports::IrsMonthlyManifest.new.create("#{@h36_root_folder}/transmission")
    end

    private

    def create_new_irs_folder(folder_count)
      folder_number = prepend_zeros(folder_count.to_s, 3)
      @h36_folder_name = "DCHBX_H36_#{Time.now.strftime('%H_%M_%d_%m_%Y')}_#{folder_number}"
      create_directory "#{@h36_root_folder}/#{@h36_folder_name}"
    end

    def prepend_zeros(number, n)
      (n - number.to_s.size).times { number.prepend('0') }
      number
    end

    def create_directory(path)
      if Dir.exists?(path)
        FileUtils.rm_rf(path)
      end
      Dir.mkdir path
    end
  end
end