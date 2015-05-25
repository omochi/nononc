require "./token"
require "./token_reader_error"

class TokenReader
	attr_reader :source
	attr_reader :pos

	def initialize(source)
		@source = source
		@pos = CharPos.new(0, 0, 0)
		@line_end_poes = []
	end
	def symbol_def
		[
			["(", LeftParenToken],
			[")", RightParenToken],
			[",", CommaToken],
			[":", ColonToken],
			[".", DotToken],
			["+", PlusToken],
			["->", ArrowToken],
			["-", MinusToken],
			["*", StarToken],
			["/", SlashToken],
			["%", PercentToken],
			["<=", LessEqToken],
			["<", LessToken],
			[">=", GreaterEqToken],
			[">", GreaterToken],
			["==", EqEqToken],
			["!=", NotEqToken],
			["=", EqualToken],
			["\t", TabToken]
		]
	end
	def is_str_end()
		if @pos.index >= @source.length
			return true
		else
			return false
		end
	end
	def get_line_end_pos(line)
		if pos = @line_end_poes[line]
			return pos
		end
		raise "unknown line: line = #{line}"
	end
	def set_line_end_pos(line, pos)
		if line < @line_end_poes.length - 1
			raise "last line only editable: line = #{line}, line_end_poes.length = #{@line_end_poes.length}"
		end
		@line_end_poes.push(pos)
	end
	def peek_char(index)
		if index < 0 || @source.length <= index
			return ""
		else
			return @source[index]
		end
	end
	def read_char()
		char1 = peek_char(@pos.index)
		if char1 == ""
			return ""
		end

		if char1 == "\r"
			char2 = peek_char(@pos.index + 1)
			if char2 == "\n"
				@pos = @pos.add(1)
			else
				set_line_end_pos(@pos.line, @pos.add(1))
				@pos = @pos.add_newline(1)
			end
		elsif char1 == "\n"
			set_line_end_pos(@pos.line, @pos.add(1))
			@pos = @pos.add_newline(1)
		else
			@pos = @pos.add(1)
		end

		return char1
	end
	def back_char(char)
		if @pos.index == 0
			raise "you can not back any more"
		end

		if @pos.column == 0
			line = @pos.line - 1
			@pos = get_line_end_pos(line)
			if @pos.column == 0
				raise "line end pos column is 0 #{@pos}"
			end
			@line_end_poes.delete_at(line)
		end
		@pos = @pos.add(-1)

		prev_char = peek_char(@pos.index)
		if prev_char != char
			raise "backed char is not equals to actual prev char: " +
				"back = #{char.inspect}, actual = #{prev_char.inspect}"
		end
	end

	def read_str(len)
		str = ""
		i = 0
		while i < len
			char = read_char()
			if char == ""
				return str
			end
			str += char
			i += 1
		end
		return str
	end
	def back_str(str)
		i = str.length - 1
		while i >= 0
			back_char(str[i])
			i -= 1
		end
	end
	def back_token(token)
		back_str(token.str)
	end

	def seek_to_pos(pos)
		current_index = self.pos.index
		to_index = pos.index
		if current_index < to_index
			raise "you can not go forward"
		end
		
		diff_len = current_index - to_index
		diff_str = @source[to_index, diff_len]
		back_str(diff_str)
	end
	
	def try_read_str(str)
		try_str = read_str(str.length)
		if try_str == str
			return try_str
		else
			back_str(try_str)
			return nil
		end
	end
	def try_read_char_cond()
		char = read_str(1)
		if yield(char)
			return char
		else
			back_str(char)
			return nil
		end
	end
	def try_read_str_cond()
		char = read_str(1)
		if not yield(char)
			back_str(char)
			return nil
		end
		str = char
		while true
			char = read_str(1)
			if not yield(char)
				back_str(char)
				return str
			else
				str += char
			end
		end
	end
	def try_read_end_token()
		token_pos = pos
		if is_str_end
			return EndToken.new("", token_pos)
		else
			return nil
		end
	end
	def try_read_newline_str()
		if str1 = try_read_str("\r")
			if str2 = try_read_str("\n")
				return str1 + str2
			else
				return str1
			end
		elsif str1 = try_read_str("\n")
			return str1
		else
			return nil
		end
	end
	def try_read_newline_token()
		token_pos = pos
		if str = try_read_newline_str()
			return NewlineToken.new(str, token_pos)
		else
			return nil
		end
	end
	def try_read_space_token()
		token_pos = pos
		if str = try_read_str_cond {|c| char_is_space(c) }
			return SpaceToken.new(str, token_pos)
		else
			return nil
		end
	end
	def try_read_symbol_token()
		token_pos = pos
		symbol_def.each {|str, klass|
			if str = try_read_str(str)
				return klass.new(str, token_pos)
			end
		}
		return nil
	end
	def try_read_keyword_token()
		token_pos = pos
		token_str = ""
		if str1 = try_read_char_cond {|c| char_is_keyword_head(c) }
			token_str += str1
			if str2 = try_read_str_cond {|c| char_is_keyword_body(c) }
				token_str += str2
			end
			return KeywordToken.new(token_str, token_pos)
		else
			return nil
		end		
	end
	def try_read_number_token_w()
		token_pos = pos
		token_str = ""
		if str1 = try_read_str("0x")
			token_str += str1
			if str2 = try_read_str_cond {|c| char_is_hex_number(c) }
				token_str += str2
				int_part_value = str2.to_i(16)
				# hexは少数無し
				return IntNumberToken.new(int_part_value, token_str, token_pos), []
			else
				error_pos = pos
				return IntNumberToken.new(0, token_str, token_pos), 
					[CharNotNumberError.new(error_pos)]
			end
		end

		if str1 = try_read_str_cond {|c| char_is_number(c) }
			token_str += str1
			int_part_value = str1.to_i(10)
		else
			# 整数部分が無かった
			return nil, []
		end

		if str2 = try_read_str(".")
			token_str += str2
		else
			# 小数部分が無かった
			return IntNumberToken.new(int_part_value, token_str, token_pos), []
		end

		if str3 = try_read_str_cond {|c| char_is_number(c) }
			token_str += str3
		else
			error_pos = pos
			return FloatNumberToken.new(int_part_value, token_str, token_pos), 
				[CharNotNumberError.new(error_pos)]
		end

		frac_part_str = str3
		frac_scale = 1.0
		frac_part_str.length.times { frac_scale *= 10.0 }
		frac_part_value = frac_part_str.to_i(10) / frac_scale

		number_value = int_part_value + frac_part_value

		return FloatNumberToken.new(number_value, token_str, token_pos), []
	end
	def try_read_line_comment_token()
		token_pos = pos
		if not str = try_read_str("//")
			return nil
		end
		while true
			if is_str_end()
				return LineCommentToken.new(str, token_pos)
			elsif nl_str = try_read_newline_str()
				back_str(nl_str)
				return LineCommentToken.new(str, token_pos)
			else
				str += read_str(1)
			end
		end
	end
	def try_read_block_comment_token_w()
		token_pos = pos
		token_str = ""
		if not str = try_read_str("/*")
			return nil, []
		end
		token_str += str
		while true
			if is_str_end()
				token = BlockCommentToken.new(token_str, token_pos)
				error_pos = pos
				return token, [BlockCommentNotClosedError.new(error_pos)]
			elsif str = try_read_str("*/")
				token_str += str
				return BlockCommentToken.new(token_str, token_pos), []
			elsif nl_str = try_read_newline_str()
				token_str += nl_str
			else
				token_str += read_str(1)
			end
		end
	end

	def read_token_w()
		token, ws, err = _read_token_we()
		if err == nil
			return token, ws
		end
		if not err.is_a?(InvalidCharError)
			raise ["unknown underling error", err]
		end

		invalid_pos = pos
		invalid_str = ""

		while true
			warns = []

			invalid_str += read_str(1)

			token, ws, err = _read_token_we()
			if err
				next
			end
			warns += ws
			back_str(token.str)

			invalid_token = InvalidToken.new(invalid_str, invalid_pos)
			warns.push(InvalidStrError.new(invalid_pos, invalid_str))

			return invalid_token, warns
		end
	end
	def _read_token_we()
		if token = try_read_end_token()
			return token, [], nil
		elsif token = try_read_newline_token()
			return token, [], nil
		elsif token = try_read_space_token()
			return token, [], nil
		elsif token = try_read_keyword_token()
			return token, [], nil
		end
		token, ws = try_read_number_token_w()
		if token
			return token, ws, nil
		end

		if token = try_read_line_comment_token()
			return token, [], nil
		end
		token, ws = try_read_block_comment_token_w()
		if token
			return token, ws, nil
		end

		if token = try_read_symbol_token()
			return token, [], nil
		end

		error_pos = pos
		return nil, [], InvalidCharError.new(error_pos)
	end

	def discard_to_eol()
		token_pos = pos
		str = ""
		while true
			if is_str_end()
				return InvalidToken.new(str, token_pos)
			elsif nl_str = try_read_newline_str()
				back_str(nl_str)
				return InvalidToken.new(str, token_pos)
			else
				str += read_str(1)
			end
		end
	end

end