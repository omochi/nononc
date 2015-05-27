class CharPos
	attr_reader :index, :line, :column
	def initialize(index, line, column)
		@index = index
		@line = line
		@column = column
	end
	def ==(cmp)
		index == cmp.index && line == cmp.line && column == cmp.column
	end
	def add(len)
		return CharPos.new(index + len, line, column + len)
	end
	def add_newline(line_str_len)
		return CharPos.new(index + line_str_len, line + 1, 0)
	end
	def to_s
		"(#{index}, #{line}, #{column})"
	end
	def inspect
		to_s
	end
end
