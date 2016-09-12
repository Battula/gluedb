# Mass generates reinstate CVs. Takes an array of policy and/or enrollment group IDs. 

policy_ids = []

policy_ids.uniq!

eg_ids = %w()

eg_ids.uniq!

reinstate_policies = Policy.where(:eg_id => {"$in" => eg_ids})

reinstate_policies.each do |policy|
	policy.enrollees.each do |enrollee|
		enrollee.coverage_end = ''
	end
	subscriber_id = policy.subscriber.m_id
	enrollee_list = policy.enrollees.all
	all_ids = enrollee_list.map(&:m_id) | [subscriber_id]
	out_file = File.open(File.join("reinstates", "Reinstate - #{policy.market} - #{policy.subscriber.person.name_full} - #{policy.eg_id}.xml"), 'w')
	reinstate_cv = CanonicalVocabulary::MaintenanceSerializer.new(
          			policy,
          			"reinstate",
          			"personnel_data",
          			all_ids,
          			all_ids
        			)
	out_file.write(reinstate_cv.serialize)
	out_file.close
end