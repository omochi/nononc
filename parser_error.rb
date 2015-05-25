class ParserError
end
class TokenError < ParserError
	attr_reader :token
	def initialize(token)
		@token = token
	end
end
class TabIndentError < TokenError
end
class TokenNotNewlineError < TokenError
end
class TokenNotKeywordError < TokenError
end
class TokenNotLeftParenError < TokenError
end
class TokenNotRightParenError < TokenError
end
class TokenNotEqualError < TokenError
end
class TokenNotArrowError < TokenError
end

class TabIndentError < TokenError
end
class InvalidIndentError < TokenError
	attr_reader :valid_len
	def initialize(token, valid_len)
		@valid_len = valid_len
		super(token)
	end
end
class InvalidNewlineError < TokenError
end
class NeedsNewlineError < TokenError
end
