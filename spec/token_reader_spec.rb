require "spec_helper"

require "./token_reader"

describe "token reader" do
	it "read char 1" do
		r = TokenReader.new("ab\nc")
		expect(r.pos).to eq CharPos.new(0, 0, 0)

		c = r.read_char()
		expect(c).to eq "a"
		expect(r.pos).to eq CharPos.new(1, 0, 1)

		c = r.read_char()
		expect(c).to eq "b"
		expect(r.pos).to eq CharPos.new(2, 0, 2)

		c = r.read_char()
		expect(c).to eq "\n"
		expect(r.pos).to eq CharPos.new(3, 1, 0)
		expect(r.get_line_end_pos(0)).to eq CharPos.new(3, 0, 3)

		c = r.read_char()
		expect(c).to eq "c"
		expect(r.pos).to eq CharPos.new(4, 1, 1)

		c = r.read_char()
		expect(c).to eq ""
		expect(r.pos).to eq CharPos.new(4, 1, 1)
	end

	it "read char 2" do
		r = TokenReader.new("a\rb")
		expect(r.pos).to eq CharPos.new(0, 0, 0)

		c = r.read_char()
		expect(c).to eq "a"
		expect(r.pos).to eq CharPos.new(1, 0, 1)

		c = r.read_char()
		expect(c).to eq "\r"
		expect(r.pos).to eq CharPos.new(2, 1, 0)
		expect(r.get_line_end_pos(0)).to eq CharPos.new(2, 0, 2)

		c = r.read_char()
		expect(c).to eq "b"
		expect(r.pos).to eq CharPos.new(3, 1, 1)

		c = r.read_char()
		expect(c).to eq ""
		expect(r.pos).to eq CharPos.new(3, 1, 1)
	end

	it "read char 3" do
		r = TokenReader.new("a\r\nb")
		expect(r.pos).to eq CharPos.new(0, 0, 0)

		c = r.read_char()
		expect(c).to eq "a"
		expect(r.pos).to eq CharPos.new(1, 0, 1)

		c = r.read_char()
		expect(c).to eq "\r"
		expect(r.pos).to eq CharPos.new(2, 0, 2)

		c = r.read_char()
		expect(c).to eq "\n"
		expect(r.pos).to eq CharPos.new(3, 1, 0)
		expect(r.get_line_end_pos(0)).to eq CharPos.new(3, 0, 3)

		c = r.read_char()
		expect(c).to eq "b"
		expect(r.pos).to eq CharPos.new(4, 1, 1)

		c = r.read_char()
		expect(c).to eq ""
		expect(r.pos).to eq CharPos.new(4, 1, 1)
	end

	it "read char 4" do
		r = TokenReader.new("a\nb")
		expect(r.pos).to eq CharPos.new(0, 0, 0)

		c1 = r.read_char()
		expect(c1).to eq "a"
		expect(r.pos).to eq CharPos.new(1, 0, 1)

		r.back_char(c1)
		expect(r.pos).to eq CharPos.new(0, 0, 0)

		c1 = r.read_char()
		c2 = r.read_char()
		expect(c2).to eq "\n"
		expect(r.pos).to eq CharPos.new(2, 1, 0)

		r.back_char(c2)
		expect(r.pos).to eq CharPos.new(1, 0, 1)
		r.back_char(c1)
		expect(r.pos).to eq CharPos.new(0, 0, 0)

		c1 = r.read_char()
		c2 = r.read_char()
		c3 = r.read_char()
		expect(c3).to eq "b"
		expect(r.pos).to eq CharPos.new(3, 1, 1)

		r.back_char(c3)
		expect(r.pos).to eq CharPos.new(2, 1, 0)
		r.back_char(c2)
		expect(r.pos).to eq CharPos.new(1, 0, 1)
		r.back_char(c1)
		expect(r.pos).to eq CharPos.new(0, 0, 0)

		c1 = r.read_char()
		c2 = r.read_char()
		c3 = r.read_char()
		c4 = r.read_char()
		expect(c4).to eq ""
		expect(r.pos).to eq CharPos.new(3, 1, 1)

		r.back_char(c3)
		expect(r.pos).to eq CharPos.new(2, 1, 0)
		r.back_char(c2)
		expect(r.pos).to eq CharPos.new(1, 0, 1)
		r.back_char(c1)
		expect(r.pos).to eq CharPos.new(0, 0, 0)
	end

	it "read char 5" do
		r = TokenReader.new("a\rb")
		expect(r.pos).to eq CharPos.new(0, 0, 0)

		c1 = r.read_char()
		expect(c1).to eq "a"
		expect(r.pos).to eq CharPos.new(1, 0, 1)
		r.back_char(c1)
		expect(r.pos).to eq CharPos.new(0, 0, 0)

		c1 = r.read_char()
		expect(c1).to eq "a"
		c2 = r.read_char()
		expect(c2).to eq "\r"
		expect(r.pos).to eq CharPos.new(2, 1, 0)
		r.back_char(c2)
		expect(r.pos).to eq CharPos.new(1, 0, 1)
		r.back_char(c1)
		expect(r.pos).to eq CharPos.new(0, 0, 0)

		c1 = r.read_char()
		expect(c1).to eq "a"
		c2 = r.read_char()
		expect(c2).to eq "\r"
		c3 = r.read_char()
		expect(c3).to eq "b"
		expect(r.pos).to eq CharPos.new(3, 1, 1)
		r.back_char(c3)
		expect(r.pos).to eq CharPos.new(2, 1, 0)
		r.back_char(c2)
		expect(r.pos).to eq CharPos.new(1, 0, 1)
		r.back_char(c1)
		expect(r.pos).to eq CharPos.new(0, 0, 0)

		c1 = r.read_char()
		expect(c1).to eq "a"
		c2 = r.read_char()
		expect(c2).to eq "\r"
		c3 = r.read_char()
		expect(c3).to eq "b"
		r.back_char(c3)
		c3 = r.read_char()
		expect(c3).to eq "b"
		r.back_char(c3)
		r.back_char(c2)
		c2 = r.read_char()
		expect(c2).to eq "\r"
		c3 = r.read_char()
		expect(c3).to eq "b"
		r.back_char(c3)
		r.back_char(c2)
		r.back_char(c1)
		c1 = r.read_char()
		expect(c1).to eq "a"
		c2 = r.read_char()
		expect(c2).to eq "\r"
		c3 = r.read_char()
		expect(c3).to eq "b"
	end

	it "read char 6" do
		r = TokenReader.new("a\r\nb")
		expect(r.pos).to eq CharPos.new(0, 0, 0)

		c1 = r.read_char()
		expect(c1).to eq "a"
		expect(r.pos).to eq CharPos.new(1, 0, 1)
		r.back_char(c1)
		expect(r.pos).to eq CharPos.new(0, 0, 0)

		c1 = r.read_char()
		expect(c1).to eq "a"
		c2 = r.read_char()
		expect(c2).to eq "\r"
		expect(r.pos).to eq CharPos.new(2, 0, 2)
		r.back_char(c2)
		expect(r.pos).to eq CharPos.new(1, 0, 1)
		r.back_char(c1)
		expect(r.pos).to eq CharPos.new(0, 0, 0)

		c1 = r.read_char()
		expect(c1).to eq "a"
		c2 = r.read_char()
		expect(c2).to eq "\r"
		c3 = r.read_char()
		expect(c3).to eq "\n"
		expect(r.pos).to eq CharPos.new(3, 1, 0)
		r.back_char(c3)
		expect(r.pos).to eq CharPos.new(2, 0, 2)
		r.back_char(c2)
		expect(r.pos).to eq CharPos.new(1, 0, 1)
		r.back_char(c1)
		expect(r.pos).to eq CharPos.new(0, 0, 0)

		c1 = r.read_char()
		expect(c1).to eq "a"
		expect(r.pos).to eq CharPos.new(1, 0, 1)
		c2 = r.read_char()
		expect(c2).to eq "\r"
		expect(r.pos).to eq CharPos.new(2, 0, 2)
		c3 = r.read_char()
		expect(c3).to eq "\n"
		expect(r.pos).to eq CharPos.new(3, 1, 0)
		c4 = r.read_char()
		expect(c4).to eq "b"
		expect(r.pos).to eq CharPos.new(4, 1, 1)
		r.back_char(c4)
		c4 = r.read_char()
		expect(c4).to eq "b"
		expect(r.pos).to eq CharPos.new(4, 1, 1)
		r.back_char(c4)
		r.back_char(c3)
		c3 = r.read_char()
		expect(c3).to eq "\n"
		expect(r.pos).to eq CharPos.new(3, 1, 0)
		c4 = r.read_char()
		expect(c4).to eq "b"
		expect(r.pos).to eq CharPos.new(4, 1, 1)
		r.back_char(c4)
		r.back_char(c3)
		r.back_char(c2)
		c2 = r.read_char()
		expect(c2).to eq "\r"
		expect(r.pos).to eq CharPos.new(2, 0, 2)
		c3 = r.read_char()
		expect(c3).to eq "\n"
		expect(r.pos).to eq CharPos.new(3, 1, 0)
		c4 = r.read_char()
		expect(c4).to eq "b"
		expect(r.pos).to eq CharPos.new(4, 1, 1)
		r.back_char(c4)
		r.back_char(c3)
		r.back_char(c2)
		r.back_char(c1)
		c1 = r.read_char()
		expect(c1).to eq "a"
		expect(r.pos).to eq CharPos.new(1, 0, 1)
		c2 = r.read_char()
		expect(c2).to eq "\r"
		expect(r.pos).to eq CharPos.new(2, 0, 2)
		c3 = r.read_char()
		expect(c3).to eq "\n"
		expect(r.pos).to eq CharPos.new(3, 1, 0)
		c4 = r.read_char()
		expect(c4).to eq "b"
		expect(r.pos).to eq CharPos.new(4, 1, 1)
	end

	it "read str 1" do
		r = TokenReader.new("a\nb")
		expect(r.pos).to eq CharPos.new(0, 0, 0)

		s1 = r.read_str(1)
		expect(s1).to eq "a"
		expect(r.pos).to eq CharPos.new(1, 0, 1)

		s2 = r.read_str(1)
		expect(s2).to eq "\n"
		expect(r.pos).to eq CharPos.new(2, 1, 0)

		s3 = r.read_str(1)
		expect(s3).to eq "b"
		expect(r.pos).to eq CharPos.new(3, 1, 1)

		s4 = r.read_str(1)
		expect(s4).to eq ""
		expect(r.pos).to eq CharPos.new(3, 1, 1)

		r.back_str(s3)
		expect(r.pos).to eq CharPos.new(2, 1, 0)

		s3 = r.read_str(1)
		expect(s3).to eq "b"
		expect(r.pos).to eq CharPos.new(3, 1, 1)

		r.back_str(s2 + s3)
		expect(r.pos).to eq CharPos.new(1, 0, 1)

		s2 = r.read_str(2)
		expect(s2).to eq "\nb"
		expect(r.pos).to eq CharPos.new(3, 1, 1)

		r.back_str(s1 + s2)
		expect(r.pos).to eq CharPos.new(0, 0, 0)

		s1 = r.read_str(2)
		expect(s1).to eq "a\n"
		expect(r.pos).to eq CharPos.new(2, 1, 0)

		s2 = r.read_str(1)
		expect(s2).to eq "b"
		expect(r.pos).to eq CharPos.new(3, 1, 1)

		r.back_str(s1 + s2)
		expect(r.pos).to eq CharPos.new(0, 0, 0)

		s1 = r.read_str(3)
		expect(s1).to eq "a\nb"
		expect(r.pos).to eq CharPos.new(3, 1, 1)
	end

	it "read str 2" do
		r = TokenReader.new("a\rb")
		expect(r.pos).to eq CharPos.new(0, 0, 0)

		s1 = r.read_str(1)
		expect(s1).to eq "a"
		expect(r.pos).to eq CharPos.new(1, 0, 1)

		s2 = r.read_str(1)
		expect(s2).to eq "\r"
		expect(r.pos).to eq CharPos.new(2, 1, 0)

		s3 = r.read_str(1)
		expect(s3).to eq "b"
		expect(r.pos).to eq CharPos.new(3, 1, 1)

		s4 = r.read_str(1)
		expect(s4).to eq ""
		expect(r.pos).to eq CharPos.new(3, 1, 1)

		r.back_str(s3)
		expect(r.pos).to eq CharPos.new(2, 1, 0)

		s3 = r.read_str(1)
		expect(s3).to eq "b"
		expect(r.pos).to eq CharPos.new(3, 1, 1)

		r.back_str(s2 + s3)
		expect(r.pos).to eq CharPos.new(1, 0, 1)

		s2 = r.read_str(2)
		expect(s2).to eq "\rb"
		expect(r.pos).to eq CharPos.new(3, 1, 1)

		r.back_str(s1 + s2)
		expect(r.pos).to eq CharPos.new(0, 0, 0)

		s1 = r.read_str(2)
		expect(s1).to eq "a\r"
		expect(r.pos).to eq CharPos.new(2, 1, 0)

		s2 = r.read_str(1)
		expect(s2).to eq "b"
		expect(r.pos).to eq CharPos.new(3, 1, 1)

		r.back_str(s1 + s2)
		expect(r.pos).to eq CharPos.new(0, 0, 0)

		s1 = r.read_str(3)
		expect(s1).to eq "a\rb"
		expect(r.pos).to eq CharPos.new(3, 1, 1)
	end

	it "read str 3" do
		r = TokenReader.new("a\r\nb")
		expect(r.pos).to eq CharPos.new(0, 0, 0)

		s1 = r.read_str(1)
		expect(s1).to eq "a"
		expect(r.pos).to eq CharPos.new(1, 0, 1)

		s2 = r.read_str(1)
		expect(s2).to eq "\r"
		expect(r.pos).to eq CharPos.new(2, 0, 2)

		s3 = r.read_str(1)
		expect(s3).to eq "\n"
		expect(r.pos).to eq CharPos.new(3, 1, 0)

		s4 = r.read_str(1)
		expect(s4).to eq "b"
		expect(r.pos).to eq CharPos.new(4, 1, 1)

		s5 = r.read_str(1)
		expect(s5).to eq ""
		expect(r.pos).to eq CharPos.new(4, 1, 1)

		r.back_str(s4)
		expect(r.pos).to eq CharPos.new(3, 1, 0)

		s4 = r.read_str(1)
		expect(s4).to eq "b"
		expect(r.pos).to eq CharPos.new(4, 1, 1)

		r.back_str(s4)
		expect(r.pos).to eq CharPos.new(3, 1, 0)
		r.back_str(s3)
		expect(r.pos).to eq CharPos.new(2, 0, 2)

		s3 = r.read_str(2)
		expect(s3).to eq "\nb"
		expect(r.pos).to eq CharPos.new(4, 1, 1)

		r.back_str(s3)
		expect(r.pos).to eq CharPos.new(2, 0, 2)
		r.back_str(s2)
		expect(r.pos).to eq CharPos.new(1, 0, 1)

		s2 = r.read_str(2)
		expect(s2).to eq "\r\n"
		expect(r.pos).to eq CharPos.new(3, 1, 0)

		s3 = r.read_str(1)
		expect(s3).to eq "b"
		expect(r.pos).to eq CharPos.new(4, 1, 1)

		r.back_str(s3)
		expect(r.pos).to eq CharPos.new(3, 1, 0)
		r.back_str(s2)
		expect(r.pos).to eq CharPos.new(1, 0, 1)
		r.back_str(s1)
		expect(r.pos).to eq CharPos.new(0, 0, 0)

		s1 = r.read_str(2)
		expect(s1).to eq "a\r"
		expect(r.pos).to eq CharPos.new(2, 0, 2)

		s2 = r.read_str(1)
		expect(s2).to eq "\n"
		expect(r.pos).to eq CharPos.new(3, 1, 0)

		r.back_str(s2)
		expect(r.pos).to eq CharPos.new(2, 0, 2)

		s2 = r.read_str(2)
		expect(s2).to eq "\nb"
		expect(r.pos).to eq CharPos.new(4, 1, 1)

		r.back_str(s2)
		expect(r.pos).to eq CharPos.new(2, 0, 2)
		r.back_str(s1)
		expect(r.pos).to eq CharPos.new(0, 0, 0)
	end

	it "try_read_end_token 1" do
		r = TokenReader.new("")

		token = r.try_read_end_token()
		expect(token).to be_a EndToken
		expect(token.pos).to eq CharPos.new(0, 0, 0)
	end

	it "try_read_end_token 2" do
		r = TokenReader.new("a")

		token = r.try_read_end_token()
		expect(token).to be_nil
	end

	it "try_read_newline_token 1" do
		r = TokenReader.new("\n")

		token = r.try_read_newline_token()
		expect(token).to be_a NewlineToken
		expect(token.str).to eq "\n"
		expect(token.pos).to eq CharPos.new(0, 0, 0)
	end

	it "try_read_newline_token 2" do
		r = TokenReader.new("a")

		token = r.try_read_newline_token()
		expect(token).to be_nil
	end

	it "try_read_space_token" do
		r = TokenReader.new("    \n")

		token = r.try_read_space_token()
		expect(token).to be_a SpaceToken
		expect(token.str).to eq "    "
		expect(token.pos).to eq CharPos.new(0, 0, 0)

		token = r.try_read_newline_token()
		expect(token).to be_a NewlineToken
		expect(token.pos).to eq CharPos.new(4, 0, 4)

		token = r.try_read_end_token()
		expect(token).to be_a EndToken
		expect(token.pos).to eq CharPos.new(5, 1, 0)
	end

	it "try_read_keyword_token" do
		r = TokenReader.new("a bb  ccc\ndddd")

		token = r.try_read_keyword_token()
		expect(token).to be_a KeywordToken
		expect(token.str).to eq "a"
		expect(token.pos).to eq CharPos.new(0, 0, 0)

		token = r.try_read_keyword_token()
		expect(token).to be_nil
		token = r.try_read_space_token()
		expect(token).to be_a SpaceToken

		token = r.try_read_keyword_token()
		expect(token).to be_a KeywordToken
		expect(token.str).to eq "bb"
		expect(token.pos).to eq CharPos.new(2, 0, 2)

		token = r.try_read_keyword_token()
		expect(token).to be_nil
		token = r.try_read_space_token()
		expect(token).to be_a SpaceToken
		
		token = r.try_read_keyword_token()
		expect(token).to be_a KeywordToken
		expect(token.str).to eq "ccc"
		expect(token.pos).to eq CharPos.new(6, 0, 6)

		token = r.try_read_newline_token()
		expect(token).to be_a NewlineToken

		token = r.try_read_keyword_token()
		expect(token).to be_a KeywordToken
		expect(token.str).to eq "dddd"
		expect(token.pos).to eq CharPos.new(10, 1, 0)
	end

	it "try_read_number_token 1" do
		r = TokenReader.new("0")
		token, ws = r.try_read_number_token_w()
		expect(token).to be_a IntNumberToken
		expect(token.value).to eq 0
		expect(ws.length).to eq 0
	end

	it "try_read_number_token 2" do
		r = TokenReader.new("0x")
		token, ws = r.try_read_number_token_w()
		expect(token).to be_a IntNumberToken
		expect(ws.length).to eq 1
		expect(ws[0]).to be_a CharNotNumberError
		expect(ws[0].pos).to eq CharPos.new(2, 0, 2)
	end

	it "try_read_number_token 3" do
		r = TokenReader.new("0xa")
		token, ws = r.try_read_number_token_w()
		expect(token).to be_a IntNumberToken
		expect(token.value).to eq 10
		expect(ws.length).to eq 0
	end

	it "try_read_number_token 4" do
		r = TokenReader.new("0x14")
		token, ws = r.try_read_number_token_w()
		expect(token).to be_a IntNumberToken
		expect(token.value).to eq 20
		expect(ws.length).to eq 0
	end

	it "try_read_number_token 5" do
		r = TokenReader.new("12.")
		token, ws = r.try_read_number_token_w()
		expect(token).to be_a FloatNumberToken
		expect(token.value).to eq 12
		expect(ws.length).to eq 1
		expect(ws[0]).to be_a CharNotNumberError
		expect(ws[0].pos).to eq CharPos.new(3, 0, 3)
	end

	it "try_read_number_token 6" do
		r = TokenReader.new("12.34")
		token, ws = r.try_read_number_token_w()
		expect(token).to be_a FloatNumberToken
		expect(token.value).to eq 12.34
		expect(ws.length).to eq 0
	end

	it "try_read_line_comment_token" do
		r = TokenReader.new(
			"// aaa bbb\n" +
			"ccc // ddd"
		)
		token = r.try_read_line_comment_token()
		expect(token).to be_a LineCommentToken
		expect(token.str).to eq "// aaa bbb"

		token = r.try_read_newline_token()
		expect(token).to be_a NewlineToken

		token = r.try_read_keyword_token()
		expect(token).to be_a KeywordToken

		token = r.try_read_space_token()
		expect(token).to be_a SpaceToken

		token = r.try_read_line_comment_token()
		expect(token).to be_a LineCommentToken
		expect(token.str).to eq "// ddd"
	end

	it "try_read_block_comment_token" do
		r = TokenReader.new(
			"/**/\n" + 
			"/* aaa\n" +
			"bbb */\n" +
			"/* aaa\n" +
			"\n" +
			"*/"
			)
		token, ws = r.try_read_block_comment_token_w()
		expect(token).to be_a BlockCommentToken
		expect(token.str).to eq "/**/"
		expect(token.pos).to eq CharPos.new(0, 0, 0)
		expect(token.end_pos).to eq CharPos.new(4, 0, 4)
	
		token = r.try_read_newline_token()
		expect(token).to be_a NewlineToken

		token, ws = r.try_read_block_comment_token_w()
		expect(token).to be_a BlockCommentToken
		expect(token.str).to eq "/* aaa\nbbb */"
		expect(token.pos).to eq CharPos.new(5, 1, 0)
		expect(token.end_pos).to eq CharPos.new(18, 2, 6)

		token = r.try_read_newline_token()
		expect(token).to be_a NewlineToken

		token, ws = r.try_read_block_comment_token_w()
		expect(token).to be_a BlockCommentToken
		expect(token.str).to eq "/* aaa\n\n*/"
		expect(token.pos).to eq CharPos.new(19, 3, 0)
		expect(token.end_pos).to eq CharPos.new(29, 5, 2)
	end

	it "read, back" do
		r = TokenReader.new(
			"abcd\n" +
			"efg")
		expect(r.pos).to eq CharPos.new(0, 0, 0)

		tokens = []
		token, ws = r.read_token_w()
		tokens.push(token)
		expect(token).to be_a KeywordToken
		expect(token.str).to eq "abcd"
		expect(token.pos).to eq CharPos.new(0, 0, 0)
		expect(token.end_pos).to eq CharPos.new(4, 0, 4)
		expect(r.pos).to eq CharPos.new(4, 0, 4)

		token, ws = r.read_token_w()
		tokens.push(token)
		expect(token).to be_a NewlineToken
		expect(token.str).to eq "\n"
		expect(token.pos).to eq CharPos.new(4, 0, 4)
		expect(token.end_pos).to eq CharPos.new(5, 1, 0)
		expect(r.pos).to eq CharPos.new(5, 1, 0)

		token, ws = r.read_token_w()
		tokens.push(token)
		expect(token).to be_a KeywordToken
		expect(token.str).to eq "efg"
		expect(token.pos).to eq CharPos.new(5, 1, 0)
		expect(token.end_pos).to eq CharPos.new(8, 1, 3)

		token, ws = r.read_token_w()
		tokens.push(token)
		expect(token).to be_a EndToken
		expect(token.pos).to eq CharPos.new(8, 1, 3)
		expect(r.pos).to eq CharPos.new(8, 1, 3)

		r.back_token(tokens.pop())
		expect(r.pos).to eq CharPos.new(8, 1, 3)

		r.back_token(tokens.pop())
		expect(r.pos).to eq CharPos.new(5, 1, 0)

		r.back_token(tokens.pop())
		expect(r.pos).to eq CharPos.new(4, 0, 4)

		r.back_token(tokens.pop())
		expect(r.pos).to eq CharPos.new(0, 0, 0)
	end

	it "space" do
		r = TokenReader.new(
			"   \n" +
			" "
			)

		token, ws = r.read_token_w()
		expect(token).to be_a SpaceToken
		expect(token.str).to eq "   "

		token, ws = r.read_token_w()
		expect(token).to be_a NewlineToken

		token, ws = r.read_token_w()
		expect(token.str).to eq " "
	end

	it "tab" do
		r = TokenReader.new("    \t")
		token, ws = r.read_token_w()
		expect(token).to be_a SpaceToken
		expect(token.str).to eq "    "

		token, ws = r.read_token_w()
		expect(token).to be_a TabToken
		expect(token.str).to eq "\t"
	end

	it "num_hex 1" do
		r = TokenReader.new("0x")
		token, ws = r.read_token_w()
		expect(token).to be_a IntNumberToken
		expect(ws[0]).to be_a CharNotNumberError
		expect(ws[0].pos).to eq CharPos.new(2, 0, 2)
	end

	it "num_hex 2" do
		r = TokenReader.new("0xa2")
		token, ws = r.read_token_w()
		expect(token.value).to eq 162
		expect(token.str).to eq "0xa2"
	end

	it "num_dec 1" do
		r = TokenReader.new("10")
		token, ws = r.read_token_w()
		expect(token.value).to eq 10
		expect(token.str).to eq "10"
	end

	it "num_dec 2" do
		r = TokenReader.new("10.")
		token, ws = r.read_token_w()
		expect(token).to be_a FloatNumberToken
		expect(ws[0]).to be_a CharNotNumberError
		expect(ws[0].pos).to eq CharPos.new(3, 0, 3)
	end

	it "num_dec 3" do
		r = TokenReader.new("10.12")
		token, ws = r.read_token_w()
		expect(token.value).to eq 10.12
	end


	it "comment 1" do
		r = TokenReader.new(
			"abc\n" +
			"// comment/*\n" +
			"ddd /* eee//\n" +
			"ggg */ hhh\n"
			)

		token, ws = r.read_token_w()
		expect(token).to be_a KeywordToken
		expect(token.str).to eq "abc"

		token, ws = r.read_token_w()
		expect(token).to be_a NewlineToken
		expect(r.pos).to eq CharPos.new(4, 1, 0)

		token, ws = r.read_token_w()
		expect(token).to be_a LineCommentToken
		expect(token.str).to eq "// comment/*"
		expect(token.pos).to eq CharPos.new(4, 1, 0)
		expect(r.pos).to eq CharPos.new(16, 1, 12)

		token, ws = r.read_token_w()
		expect(token).to be_a NewlineToken

		token, ws = r.read_token_w()
		expect(token).to be_a KeywordToken
		expect(token.str).to eq "ddd"

		token, ws = r.read_token_w()
		expect(token).to be_a SpaceToken

		token, ws = r.read_token_w()
		expect(token).to be_a BlockCommentToken
		expect(token.str).to eq "/* eee//\nggg */"
		expect(token.pos).to eq CharPos.new(21, 2, 4)

		token, ws = r.read_token_w()
		expect(token).to be_a SpaceToken

		token, ws = r.read_token_w()
		expect(token).to be_a KeywordToken
		expect(token.str).to eq "hhh"
	end

	it "comment 2" do 
		r = TokenReader.new(
			"/**/\n"+
			"/*  */\n"+
			"   /* aaa\n"+
			"*/\n" +
			"  /* bbb\n"+
			"   ccc\n" +
			"ddd */")

		token, ws = r.read_token_w()
		expect(token).to be_a BlockCommentToken
		expect(token.str).to eq "/**/"
		expect(token.pos).to eq CharPos.new(0, 0, 0)

		token, ws = r.read_token_w() 
		expect(token).to be_a NewlineToken

		token, ws = r.read_token_w()
		expect(token).to be_a BlockCommentToken
		expect(token.str).to eq "/*  */"
		expect(token.pos).to eq CharPos.new(5, 1, 0)

		token, ws = r.read_token_w() 
		expect(token).to be_a NewlineToken

		token, ws = r.read_token_w() 
		expect(token).to be_a SpaceToken
		token, ws = r.read_token_w()
		expect(token).to be_a BlockCommentToken
		expect(token.str).to eq "/* aaa\n*/"
		expect(token.pos).to eq CharPos.new(15, 2, 3)

		token, ws = r.read_token_w()
		expect(token).to be_a NewlineToken

		token, ws = r.read_token_w() 
		expect(token).to be_a SpaceToken
		token, ws = r.read_token_w()
		expect(token).to be_a BlockCommentToken
		expect(token.str).to eq "/* bbb\n   ccc\nddd */"
		expect(token.pos).to eq CharPos.new(27, 4, 2)

		token, ws = r.read_token_w()
		expect(token).to be_a EndToken
	end

	it "comment 3" do 
		r = TokenReader.new(
			"/* aa\n" +
			" bb")
		token, ws = r.read_token_w()
		expect(token).to be_a BlockCommentToken
		expect(token.str).to eq "/* aa\n bb"
		expect(ws[0]).to be_a BlockCommentNotClosedError
		expect(ws[0].pos).to eq CharPos.new(9, 1, 3)
	end

	it "invalid 1" do
		r = TokenReader.new("aaaあいう")

		token, ws = r.read_token_w()
		expect(token).to be_a KeywordToken
		expect(token.str).to eq "aaa"

		token, ws = r.read_token_w()
		expect(token).to be_a InvalidToken
		expect(token.str).to eq "あいう"
		expect(ws[0]).to be_a InvalidStrError
		expect(ws[0].pos).to eq CharPos.new(3, 0, 3)
		expect(ws[0].str).to eq "あいう"
		expect(r.pos).to eq CharPos.new(6, 0, 6)

		token, ws = r.read_token_w()
		expect(token).to be_a EndToken
	end

	it "invalid 2" do
		r = TokenReader.new("aaaあいうbbb")

		token, ws = r.read_token_w()
		expect(token).to be_a KeywordToken
		expect(token.str).to eq "aaa"

		token, ws = r.read_token_w()
		expect(token).to be_a InvalidToken
		expect(token.str).to eq "あいう"
		expect(ws[0]).to be_a InvalidStrError
		expect(ws[0].pos).to eq CharPos.new(3, 0, 3)
		expect(ws[0].str).to eq "あいう"

		token, ws = r.read_token_w()
		expect(token).to be_a KeywordToken
		expect(token.str).to eq "bbb"

		token, ws = r.read_token_w()
		expect(token).to be_a EndToken
	end

	it "discard_to_eol 1" do
		r = TokenReader.new("aaa bbb ccc ddd\neee")

		token, ws = r.read_token_w()
		expect(token.str).to eq "aaa"

		token, ws = r.read_token_w()
		expect(token.str).to eq " "

		token, ws = r.read_token_w()
		expect(token.str).to eq "bbb"

		token = r.discard_to_eol()
		expect(token).to be_a InvalidToken
		expect(token.str).to eq " ccc ddd"
		expect(token.pos).to eq CharPos.new(7, 0, 7)

		token, ws = r.read_token_w()
		expect(token.str).to eq "\n"
	end

	it "discard_to_eol 2" do
		r = TokenReader.new("aaa bbb ccc ddd")

		token, ws = r.read_token_w()
		expect(token.str).to eq "aaa"

		token, ws = r.read_token_w()
		expect(token.str).to eq " "

		token, ws = r.read_token_w()
		expect(token.str).to eq "bbb"

		token = r.discard_to_eol()
		expect(token).to be_a InvalidToken
		expect(token.str).to eq " ccc ddd"
		expect(token.pos).to eq CharPos.new(7, 0, 7)

		token, ws = r.read_token_w()
		expect(token).to be_a EndToken
	end

	it "seek_to_pos 1" do
		r = TokenReader.new("aaa bbb ccc ddd")

		token1, ws = r.read_token_w()
		expect(token1.str).to eq "aaa"

		token2, ws = r.read_token_w()
		expect(token2.str).to eq " "

		token3, ws = r.read_token_w()
		expect(token3.str).to eq "bbb"

		token4 = r.discard_to_eol()
		expect(token4).to be_a InvalidToken
		expect(token4.str).to eq " ccc ddd"

		r.seek_to_pos(token1.pos)
		expect(r.pos).to eq CharPos.new(0, 0, 0)

		token1, ws = r.read_token_w()
		expect(token1.str).to eq "aaa"
	end

	it "seek_to_pos 2" do
		r = TokenReader.new("aaa\nbbb")

		token1, ws = r.read_token_w()
		expect(token1.str).to eq "aaa"

		token2, ws = r.read_token_w()
		expect(token2.str).to eq "\n"
		
		token3, ws = r.read_token_w()
		expect(token3.str).to eq "bbb"
		
		r.seek_to_pos(token2.pos)
		expect(r.pos).to eq CharPos.new(3, 0, 3)

		token2, ws = r.read_token_w()
		expect(token2.str).to eq "\n"
	end

end