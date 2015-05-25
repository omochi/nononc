def string_split_into_lines(str)
	lines = []
	index = 0
	begin_index = 0
	while true
		if index == str.length
			break
		end
		char1 = str[index]
		if char1 == "\r"
			index += 1
			if index < str.length
				char2 = str[index]
				if char2 == "\n"
					index += 1
					lines.push(str[begin_index, (index - begin_index)])
					begin_index = index
					next
				end
			end
			lines.push(str[begin_index, (index - begin_index)])
			begin_index = index
		elsif char1 == "\n"
			index += 1
			lines.push(str[begin_index, (index - begin_index)])
			begin_index = index
		else
			index += 1
		end
	end
	lines.push(str[begin_index, (index - begin_index)])
	return lines
end