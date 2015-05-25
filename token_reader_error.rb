class TokenReaderError
	attr_reader :pos
	def initialize(pos)
		@pos = pos
	end
end
class InvalidCharError < TokenReaderError
end
class InvalidStrError < TokenReaderError
	attr_reader :str
	def initialize(pos, str)
		@str = str
		super(pos)
	end
end
class CharNotNumberError < TokenReaderError
end
class BlockCommentNotClosedError < TokenReaderError
end