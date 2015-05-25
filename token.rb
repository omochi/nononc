require "./char"
require "./string"
require "./char_pos"

class Token
	attr_reader :str, :pos, :end_pos
	def initialize(str, pos)
		@str = str
		@pos = pos

		lines = string_split_into_lines(str)
		line_num = lines.length

		end_pos = pos
		i = 0
		while i < line_num - 1
			end_pos = end_pos.add_newline(lines[i].length)
			i += 1
		end
		end_pos = end_pos.add(lines[line_num - 1].length)

		@end_pos = end_pos
	end
	def is_comment
		false
	end
	def is_term_operator
		false
	end
	def is_factor_operator
		false
	end
	def is_eol
		false
	end
end
class InvalidToken < Token
end
class EndToken < Token
	def is_eol
		true
	end
end
class NewlineToken < Token
	def is_eol
		true
	end
end
class SpaceToken < Token
end
class TabToken < Token
end
class KeywordToken < Token
end
class IntNumberToken < Token
	attr_reader :value
	def initialize(value, str, pos)
		@value = value
		super(str, pos)
	end
end
class FloatNumberToken < Token
	attr_reader :value
	def initialize(value, str, pos)
		@value = value
		super(str, pos)
	end
end
class LineCommentToken < Token
	def is_comment
		true
	end
end
class BlockCommentToken < Token
	def is_comment
		true
	end
end

class LeftParenToken < Token
end
class RightParenToken < Token
end
class CommaToken < Token
end
class ColonToken < Token
end
class DotToken < Token
end
class PlusToken < Token
	def is_term_operator
		true
	end
end
class ArrowToken < Token
end
class MinusToken < Token
	def is_term_operator
		true
	end
end
class StarToken < Token
	def is_factor_operator
		true
	end
end
class SlashToken < Token
	def is_factor_operator
		true
	end
end
class PercentToken < Token
	def is_factor_operator
		true
	end
end
class LessEqToken < Token
end
class LessToken < Token
end
class GreaterEqToken < Token
end
class GreaterToken < Token
end
class EqEqToken < Token
end
class NotEqToken < Token
end
class EqualToken < Token
end