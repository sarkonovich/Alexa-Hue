def fix_schedule_syntax(string)
  sub_time = string.match(/time \d{2}:\d{2}/)
  sub_duration = string.match(/schedule PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?/)

  if sub_time
    sub_time = sub_time.to_s
    string.slice!(sub_time).strip
    string << " #{sub_time}"
    string.sub!("time", "schedule at")
  end

  if sub_duration
    sub_duration = sub_duration.to_s
    string.slice!(sub_duration).strip
    sub_duration = ChronicDuration.parse(sub_duration.split(' ').last)
    string << " schedule in #{sub_duration} seconds"
  end
  string.strip if string
end
