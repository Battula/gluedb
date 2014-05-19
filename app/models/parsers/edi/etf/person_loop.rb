module Parsers
  module Edi
    module Etf
      class PersonLoop
        def initialize(l2000)
          @loop = l2000
        end

        def member_id
          @member_id ||= (@loop["REFs"].detect do |r|
              r[1] == "17"
            end)[2]            
        end

        def carrier_member_id
          # TODO: Memoize this, but account for nil
          get_carrier_member_id
        end

        def get_carrier_member_id
            c_member_seg = (@loop["REFs"].detect do |r|
              r[1] == "23"
            end)
            c_member_seg.nil? ? nil : c_member_seg[2]
        end

        def rel_code
          @rel_code ||= @loop["INS"][2]
        end

        def ben_stat
          @ben_stat ||= @loop["INS"][5]
        end

        def emp_stat
          @emp_stat ||= @loop["INS"][8]
        end

        def subscriber?
          @subscriber ||= (@loop["INS"][2].strip == "18")
        end

        def policy_loops
          loops = []
          @loop["L2300s"].each do |raw_loop|
            loops << PolicyLoop.new(raw_loop)
          end
          loops
        end

        def gender_code
          @gender_code ||= @loop["L2100A"]["DMG"][3]
        end

        def relationship
          @relationship ||= map_relationship_code(rel_code)
        end

        def group_relationship
          @relationship_code ||= map_relationship_to(rel_code, gender_code)
        end

        def responsible_party?
          @responsible_party ||= !(@loop["L2100F"].blank? && @loop["L2100G"].blank?) 
        end

        def map_relationship_code(r_code)
          relationship_codes = {
            "18" => "self",
            "01" => "spouse",
            "19" => "child",
            "15" => "ward"
          }
          result = relationship_codes[r_code]
          result.nil? ? "child" : result
        end

        def map_relationship_to(r_code, gender_code)
          return "other relationship" if responsible_party?
          relationship_codes = {
            ["18", "M"] => "self",
            ["18", "F"] => "self",
            ["01", "M"] => "spouse",
            ["01", "F"] => "spouse",
            ["03", "M"] => "father",
            ["03", "F"] => "mother",
            ["04", "M"] => "grandfather",
            ["04", "F"] => "grandmother",
            ["05", "M"] => "grandson",
            ["05", "F"] => "granddaughter",
            ["06", "M"] => "uncle",
            ["06", "F"] => "aunt",
            ["07", "M"] => "nephew",
            ["07", "F"] => "niece",
            ["08", "M"] => "cousin",
            ["08", "F"] => "cousin",
            ["09", "M"] => "adopted child",
            ["09", "F"] => "adopted child",
            ["10", "M"] => "foster child",
            ["10", "F"] => "foster child",
            ["11", "M"] => "son-in-law",
            ["11", "F"] => "daughter-in-law",
            ["12", "M"] => "brother-in-law",
            ["12", "F"] => "sister-in-law",
            ["13", "M"] => "father-in-law",
            ["13", "F"] => "mother-in-law",
            ["14", "M"] => "brother",
            ["14", "F"] => "sister",
            ["15", "M"] => "ward",
            ["15", "F"] => "ward",
            ["16", "M"] => "stepparent",
            ["16", "F"] => "stepparent",
            ["17", "M"] => "stepson",
            ["17", "F"] => "stepdaughter",
            ["19", "M"] => "child",
            ["19", "F"] => "child",
            ["23", "M"] => "sponsored dependent",
            ["23", "F"] => "sponsored dependent",
            ["24", "M"] => "dependent of a minor dependent",
            ["24", "F"] => "dependent of a minor dependent",
            ["25", "M"] => "ex-spouse",
            ["25", "F"] => "ex-spouse",
            ["26", "M"] => "guardian",
            ["26", "F"] => "guardian",
            ["31", "M"] => "court appointed guardian",
            ["31", "F"] => "court appointed guardian",
            ["38", "M"] => "collateral dependent",
            ["38", "F"] => "collateral dependent",
            ["53", "M"] => "life partner",
            ["53", "F"] => "life partner",
            ["60", "M"] => "annuitant",
            ["60", "F"] => "annuitant",
            ["D2", "M"] => "trustee",
            ["D2", "F"] => "trustee",
            ["G8", "M"] => "other relationship",
            ["G8", "F"] => "other relationship",
            ["G9", "M"] => "other relative",
            ["G9", "F"] => "other relative"
          }
          result = relationship_codes[[r_code,gender_code]]
          result.nil? ? "child" : result
        end
      end
    end
  end
end
