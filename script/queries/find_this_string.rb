# Loops through transactions with no policy IDs to find a specified string. Useful for querying transacations that did not process correctly.

string_to_find = ""

transactions = Protocols::X12::TransactionSetHeader.where(policy_id: nil)


puts "#{transactions.count} transactions"

count = 0

transactions.each do |transaction|
	count += 1
	puts count if count % 1000 == 0
	body = transaction.body.read
	if body.match(string_to_find)
		puts transaction._id
		puts body
	end
end