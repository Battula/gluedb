module ChangeSets
  class PersonNameChangeSet
    def perform_update(person, person_resource, policies_to_notify, transmit = true)
      old_values_hash = old_name_values(person_resource.hbx_member_id, person, person_resource)
      old_id_hash = old_name_hash(person_resource.hbx_member_id, person, person_resource)
      update_value = person.update_attributes(name_update_hash(person_resource))
      return false unless update_value
      policies_to_notify.each do |pol|
        af = ::BusinessProcesses::AffectedMember.new({
          :policy => pol
        }.merge(old_id_hash))
        ict = IdentityChangeTransmitter.new(af, pol, "urn:openhbx:terms:v1:enrollment#change_member_name_or_demographic")
        ict.publish
        if pol.is_shop?
          serializer = ::CanonicalVocabulary::IdInfoSerializer.new(
            pol, "change", "change_in_identifying_data_elements", [person_resource.hbx_member_id], pol.active_member_ids, old_values_hash
          )
          cv = serializer.serialize
          pubber = ::Services::NfpPublisher.new
          pubber.publish(true, "#{pol.eg_id}.xml", cv)
        end
      end
      true
    end

    def name_update_hash(person_resource)
      name_hash = {
        "name_first" => person_resource.name_first,
        "name_last" => person_resource.name_last
      }
      name_hash["name_middle"] = person_resource.name_middle.blank? ? nil : person_resource.name_middle 
      name_hash["name_pfx"] = person_resource.name_pfx.blank? ? nil : person_resource.name_pfx 
      name_hash["name_sfx"] = person_resource.name_sfx.blank? ? nil : person_resource.name_sfx
      name_hash
    end

    def old_name_hash(member_id, person, person_resource)
      old_values_hash = {
        "member_id" => member_id
      }
      old_values_hash["name_first"] = person.name_first
      old_values_hash["name_last"] = person.name_last
      old_values_hash["name_middle"] = person.name_middle
      old_values_hash["name_pfx"] = person.name_pfx
      old_values_hash["name_sfx"] = person.name_sfx
      old_values_hash
    end

    def old_name_values(member_id, person, person_resource)
      old_values_hash = {
        "member_id" => member_id
      }
      old_values_hash["name_first"] = person.name_first
      old_values_hash["name_last"] = person.name_last
      if person.name_middle != person_resource.name_middle
        if !person.name_middle.blank?
          old_values_hash["name_middle"] = person.name_middle
        end
      end
      if person.name_pfx != person_resource.name_pfx
        if !person.name_pfx.blank?
          old_values_hash["name_pfx"] = person.name_pfx
        end
      end
      if person.name_sfx != person_resource.name_sfx
        if !person.name_sfx.blank?
          old_values_hash["name_sfx"] = person.name_sfx
        end
      end
      [old_values_hash]
    end
  end
end
