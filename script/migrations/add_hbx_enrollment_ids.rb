def random_start(max_size)
  highest = max_size - 501
  return 0 if highest < 1
  rand(highest)
end


def new_thread(thread_no)
Process.fork {
  error_bug = []
  puts "Starting thread #{thread_no}..."
  count = Policy.where(hbx_enrollment_ids: nil).count
  while (count > 0) do
    if count == error_bug.length
      exit(0)
    end
    skip_no = random_start(count)
    Policy.where(hbx_enrollment_ids: nil).skip(skip_no).limit(500).each do |pol|
      begin
        pol.hbx_enrollment_ids = [ pol.eg_id ]
        pol.save!
      rescue Exception => e
        puts "=========="
        puts pol.eg_id
        puts e.message
        error_bug = (error_bug + [pol.eg_id]).uniq
      end
    end
    count = Policy.where(hbx_enrollment_ids: nil).count
  end
}
end

(0..3).to_a.map { |a| new_thread(a) }.each do |t|
  Process.waitpid(t)
end
