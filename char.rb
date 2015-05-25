def char_is_in_range(char, left, right)
	if char.length == 0
		return false
	else
		return left.ord <= char.ord && char.ord <= right.ord
	end
end
def char_is_small_abc(char)
	return char_is_in_range(char, "a", "z")
end
def char_is_large_abc(char)
	return char_is_in_range(char, "A", "Z")
end
def char_is_abc(char)
	return char_is_small_abc(char) || char_is_large_abc(char)
end
def char_is_number(char)
	return char_is_in_range(char, "0", "9")
end
def char_is_hex_number(char)
	return char_is_number(char) || 
		char_is_in_range(char, "a", "f") || 
		char_is_in_range(char, "A", "F")
end
def char_is_keyword_head(char)
	return char_is_abc(char) || char == "_"
end
def char_is_keyword_body(char)
	return char_is_keyword_head(char) || char_is_number(char)
end
def char_is_space(char)
	return char == " "
end
