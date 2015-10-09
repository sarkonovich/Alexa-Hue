def fix_schedule_syntax(string)
	sub_time = string.match(/time \d{2}:\d{2}/)
	sub_duration = string.match(/schedule .*? (m|s|h)/)

	if sub_time
		sub_time = sub_time.to_s
		string.slice!(sub_time).strip
		string << " #{sub_time}"
		string.sub!("time", "schedule at")
	end

	if sub_duration
		sub_duration = sub_duration.to_s
		string.slice!(sub_duration).strip
		string << " #{sub_duration}"
		string.sub!("schedule", "schedule in")
		string.sub!(/ m$/, " minute")
    string.sub!(/ h$/, " hour")
    string.sub!(/ s$/, " second")
	end
	string.strip if string
end
