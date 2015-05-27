require "spec_helper"

require "./parser"

describe "parser" do

	it "read_space_tokens" do
		r = Parser.new("   \n\t\n  ")
		_, ws = r.read_space_tokens_w()
		expect(ws.length).to eq 1
		expect(ws[0]).to be_a TabIndentError
		expect(ws[0].token).to be_a TabToken
		expect(ws[0].token.pos).to eq CharPos.new(4, 1, 0)
		expect(ws[0].token.str).to eq "\t"

		expect(r.token_reader.pos).to eq CharPos.new(8, 2, 2)
	end

	it "read_oneline_space_tokens" do
		r = Parser.new("   \n\t\n  ")
		_, ws = r.read_oneline_space_tokens_w()
		expect(r.token_reader.pos).to eq CharPos.new(3, 0, 3)
		_, ws = r.read_oneline_space_tokens_w()
		expect(r.token_reader.pos).to eq CharPos.new(3, 0, 3)

		token, ws = r.read_token_w()
		expect(token).to be_a NewlineToken

		_, ws = r.read_oneline_space_tokens_w()
		expect(r.token_reader.pos).to eq CharPos.new(5, 1, 1)

		token, ws = r.read_token_w()
		expect(token).to be_a NewlineToken
		expect(r.token_reader.pos).to eq CharPos.new(6, 2, 0)		

		_, ws = r.read_oneline_space_tokens_w()
		expect(r.token_reader.pos).to eq CharPos.new(8, 2, 2)		
	end

	it "eol 1" do
		r = Parser.new("")
		token, ws = r.read_eol_token_w()
		expect(token).to be_a EndToken
	end

	it "eol 2" do
		r = Parser.new("\n")
		token, ws = r.read_eol_token_w()
		expect(token).to be_a NewlineToken
	end

	it "eol 3" do
		r = Parser.new("aaa bbb ccc")
		token, ws = r.read_eol_token_w()
		expect(token).to be_a EndToken
		expect(ws[0]).to be_a TokenNotNewlineError
		expect(ws[0].token.str).to eq "aaa bbb ccc"
	end

	it "eol 4" do
		r = Parser.new("aaa bbb ccc\n")
		token, ws = r.read_eol_token_w()
		expect(token).to be_a NewlineToken
		expect(ws[0]).to be_a TokenNotNewlineError
		expect(ws[0].token.str).to eq "aaa bbb ccc"
	end

	it "int literal" do
		r = Parser.new("12")
		token, ws = r.read_code_token_w()
		node, ws, err = r.parse_element_we(token)
		expect(node).to be_a IntLiteralNode
		expect(node.value).to eq 12
	end

	it "float literal" do
		r = Parser.new("12.34")
		token, ws = r.read_code_token_w()
		node, ws, err = r.parse_element_we(token)
		expect(node).to be_a FloatLiteralNode
		expect(node.value).to eq 12.34
	end

	it "name 1" do
		r = Parser.new("a")
		token, ws = r.read_code_token_w()
		node, ws, err = r.parse_element_we(token)
		expect(node).to be_a NameNode
		expect(node.str).to eq "a"
	end

	it "name 2" do
		r = Parser.new("aaa")
		token, ws = r.read_code_token_w()
		node, ws, err = r.parse_element_we(token)
		expect(node).to be_a NameNode
		expect(node.str).to eq "aaa"
	end

	it "member access 1" do
		r = Parser.new("aaa.bbb")
		token, ws = r.read_code_token_w()
		expect(token).to be_a KeywordToken

		node, ws, err = r.parse_unsigned_factor_we(token)
		expect(node).to be_a MemberNode
		expect(node[0]).to be_a NameNode
		expect(node[0].str).to eq "aaa"
		expect(node[1]).to be_a NameNode
		expect(node[1].str).to eq "bbb"
	end

	it "member access 2" do
		r = Parser.new(
			"aaa.\n" +
			"  bbb")
		token, ws = r.read_code_token_w()
		expect(token).to be_a KeywordToken

		node, ws, err = r.parse_unsigned_factor_we(token)
		expect(node).to be_a MemberNode
		expect(node[0].str).to eq "aaa"
		expect(node[1].str).to eq "bbb"
	end

	it "member access 3" do
		r = Parser.new(
			"a\n" +
			".b"
			)
		token, ws = r.read_token_w()
		node, ws = r.parse_unsigned_factor_we(token)
		expect(node).to be_a NameNode
		expect(r.token_reader.pos).to eq CharPos.new(1, 0, 1)
	end
	it "member access 4" do
		r = Parser.new(
			"a\n" +
			"  .b"
			)
		token, ws = r.read_token_w()
		node, ws = r.parse_unsigned_factor_we(token)
		expect(ws[0]).to be_nil
	end
	it "member access 5" do
		r = Parser.new(
			"a\n" +
			"   .b"
			)
		token, ws = r.read_token_w()
		node, ws = r.parse_unsigned_factor_we(token)
		expect(node).to be_a NameNode
		expect(r.token_reader.pos).to eq CharPos.new(1, 0, 1)
	end
	it "member access 6" do
		r = Parser.new(
			"a\n" +
			"  .b\n" +
			".c"
			)
		token, ws = r.read_token_w()
		node, ws = r.parse_unsigned_factor_we(token)
		expect(node).to be_a MemberNode
		expect(node[0]).to be_a NameNode
		expect(node[0].str).to eq "a"
		expect(node[1].str).to eq "b"
		expect(r.token_reader.pos).to eq CharPos.new(6, 1, 4)
	end
	it "member access 7" do
		r = Parser.new(
			"a\n" +
			"  .b\n" +
			"  .c"
			)
		token, ws = r.read_token_w()
		node, ws = r.parse_unsigned_factor_we(token)
		expect(node).to be_a MemberNode
		expect(node[0]).to be_a MemberNode
		expect(node[0][0].str).to eq "a"
		expect(node[0][1].str).to eq "b"
		expect(node[1].str).to eq "c"
		expect(ws.length).to eq 0
	end
	it "member access 8" do
		r = Parser.new(
			"a\n" +
			"  .b\n" +
			"   .c"
			)
		token, ws = r.read_token_w()
		node, ws = r.parse_unsigned_factor_we(token)
		expect(node).to be_a MemberNode
		expect(node[0]).to be_a NameNode
		expect(node[0].str).to eq "a"
		expect(node[1].str).to eq "b"
		expect(r.token_reader.pos).to eq CharPos.new(6, 1, 4)
	end
	it "member access 9" do
		r = Parser.new(
			"a\n" +
			"\n" +
			"  .b"
			)
		token, ws = r.read_token_w()
		node, ws = r.parse_unsigned_factor_we(token)
		expect(ws[0]).to be_nil
	end
	it "member access 10" do
		r = Parser.new(
			"a\n" +
			"\n" +
			"   .b"
			)
		token, ws = r.read_token_w()
		node, ws = r.parse_unsigned_factor_we(token)
		expect(node).to be_a NameNode
		expect(r.token_reader.pos).to eq CharPos.new(1, 0, 1)
	end

	it "sign 1" do
		r = Parser.new("- aaa.bbb")
		token, ws = r.read_code_token_w()
		expect(token).to be_a MinusToken

		node, ws, err = r.parse_factor_we(token)
		expect(node).to be_a MinusSignNode
		expect(node[0]).to be_a MemberNode
		expect(node[0][0].str).to eq "aaa"
		expect(node[0][1].str).to eq "bbb"
	end

	it "sign 2" do
		r = Parser.new(
			"-\n" +
			"a"
			)
		token, ws = r.read_token_w()
		node, ws, err= r.parse_factor_we(token)
		expect(err).to be_a InvalidNewlineError
	end

	it "term 1" do
		r = Parser.new("2 * 3 / 4")
		token, ws = r.read_code_token_w()
		node, ws, err = r.parse_term_we(token)
		expect(node).to be_a DivideNode
		expect(node[0]).to be_a MultiplyNode
		expect(node[0][0].value).to eq 2
		expect(node[0][1].value).to eq 3
		expect(node[1].value).to eq 4
	end

	it "term 2" do
		r = Parser.new(
			"1\n"+
			"  * 2")
		token, ws = r.read_token_w()
		node, ws, err = r.parse_term_we(token)
		expect(ws[0]).to be_nil
	end
	it "term 3" do
		r = Parser.new(
			"1\n" +
			"* 2"
			)
		token, ws = r.read_token_w()
		node, ws, err = r.parse_term_we(token)
		expect(node).to be_a IntLiteralNode
	end
	it "term 4" do
		r = Parser.new(
			"1\n" +
			"   * 2\n" +
			"\n" +
			"   * 3"
			)
		token, ws = r.read_token_w()
		node, ws, err = r.parse_term_we(token)
		expect(node).to be_a IntLiteralNode
	end
	it "term 5" do
		r = Parser.new(
			"1 *\n" +
			"    2")
		token, ws = r.read_token_w()
		node, ws, err = r.parse_term_we(token)
		expect(err).to be_a InvalidIndentError
		expect(err.token.pos).to eq CharPos.new(8, 1, 4)
	end
	it "term 6" do
		r = Parser.new(
			"\n" +
			"1")
		token, ws = r.read_token_w()
		node, ws, err = r.parse_term_we(token)
		expect(ws[0]).to be_nil
	end

	it "polynomial 1" do
		r = Parser.new("1 + 2 * 3")
		token, ws = r.read_code_token_w()
		node, ws, err = r.parse_polynomial_we(token)
		expect(node).to be_a AddNode
		expect(node[0].value).to eq 1
		expect(node[1]).to be_a MultiplyNode
		expect(node[1][0].value).to eq 2
		expect(node[1][1].value).to eq 3
	end

	it "polynomial 2" do
		r = Parser.new(
			"1 +\n" +
			"2 *\n" +
			"3"
			)
		token, ws = r.read_token_w()
		node, ws, err = r.parse_polynomial_we(token)
		expect(err).to be_a InvalidIndentError
		expect(err.token.pos).to eq CharPos.new(4, 1, 0)
	end
	it "polynomial 3" do
		r = Parser.new(
			"1 +\n" +
			"  2 *\n" +
			"  3"
			)
		token, ws = r.read_token_w()
		node, ws, err = r.parse_polynomial_we(token)
		expect(ws[0]).to be_nil
	end
	it "polynomial 4" do
		r = Parser.new(
			"1\n" +
			"+ 2"
			)
		token, ws = r.read_token_w()
		node, ws, err = r.parse_polynomial_we(token)
		expect(node).to be_a IntLiteralNode
	end

	it "expression" do
		r = Parser.new("1 + 2 * 3")
		token, ws = r.read_code_token_w()
		node, ws, err = r.parse_expression_we(token)
		expect(node).to be_a AddNode
		expect(node[0].value).to eq 1
		expect(node[1]).to be_a MultiplyNode
		expect(node[1][0].value).to eq 2
		expect(node[1][1].value).to eq 3
	end

	it "multiple expression 1" do
		r = Parser.new("aaa + bbb, ccc * ddd")
		token, ws = r.read_code_token_w()
		node, ws, err = r.parse_multiple_expression_we(token)
		expect(node).to be_a MultipleExpressionNode
		expect(node[0]).to be_a AddNode
		expect(node[0][0].str).to eq "aaa"
		expect(node[0][1].str).to eq "bbb"
		expect(node[1]).to be_a MultiplyNode
		expect(node[1][0].str).to eq "ccc"
		expect(node[1][1].str).to eq "ddd"
	end

	it "multiple expression 2" do
		r = Parser.new(
			"1 +\n" +
			"  2,\n" +
			"  3 +\n" +
			"    4,\n" +
			"  5 +\n" +
			"    6" 
			)
		token, ws = r.read_token_w()
		node, ws, err = r.parse_multiple_expression_we(token)
		expect(ws[0]).to be_nil
	end
	it "multiple expression 3" do
		r = Parser.new(
			"1 +\n" +
			"2,\n" +
			"  3 +\n" +
			"    4,\n" +
			"  5 +\n" +
			"    6" 
			)
		token, ws = r.read_token_w()
		node, ws, err = r.parse_multiple_expression_we(token)
		expect(err).to be_a InvalidIndentError
		expect(err.token.pos).to eq CharPos.new(4, 1, 0)
	end
	it "multiple expression 4" do
		r = Parser.new(
			"1 +\n" +
			"  2,\n" +
			"3 +\n" +
			"    4,\n" +
			"  5 +\n" +
			"    6" 
			)
		token, ws = r.read_token_w()
		node, ws, err = r.parse_multiple_expression_we(token)
		expect(err).to be_a InvalidIndentError
		expect(err.token.pos).to eq CharPos.new(9, 2, 0)
	end
	it "multiple expression 5" do
		r = Parser.new(
			"1 +\n" +
			"  2\n" +
			", 3 +\n" +
			"    4,\n" +
			"  5 +\n" +
			"    6" 
			)
		token, ws = r.read_token_w()
		node, ws, err = r.parse_multiple_expression_we(token)
		expect(node).to be_a MultipleExpressionNode
		expect(node.children.length).to eq 1
		expect(r.token_reader.pos).to eq CharPos.new(7, 1, 3)
	end
	it "multiple expression 6" do
		r = Parser.new(
			"1 +\n" +
			"  2\n" +
			"  , 3 +\n" +
			"    4,\n" +
			"  5 +\n" +
			"    6" 
			)
		token, ws = r.read_token_w()
		node, ws, err = r.parse_multiple_expression_we(token)
		expect(ws[0]).to be_nil
	end
	it "multiple expression 7" do
		r = Parser.new(
			"1 + 2, 3 +\n" +
			"  4,\n" +
			"  5"
			)
		token, ws = r.read_token_w()
		node, ws = r.parse_multiple_expression_we(token)
		expect(ws[0]).to be_nil
	end

	it "paren expression 1" do
		r = Parser.new("()")
		token, ws = r.read_code_token_w()
		node, ws, err = r.parse_paren_expression_we(token)
		expect(node).to be_a ParenExpressionNode
		expect(node.children.length).to eq 0
	end

	it "paren expression 2" do
		r = Parser.new("(aa, bb, cc)")
		token, ws = r.read_code_token_w()
		node, ws, err = r.parse_paren_expression_we(token)
		expect(node).to be_a ParenExpressionNode
		expect(node[0].str).to eq "aa"
		expect(node[1].str).to eq "bb"
		expect(node[2].str).to eq "cc"
	end

	it "paren expression 3" do
		r = Parser.new("a * (b + c)")
		token, ws = r.read_code_token_w()
		node, ws, err = r.parse_expression_we(token)
		expect(node).to be_a MultiplyNode
		expect(node[0].str).to eq "a"
		expect(node[1]).to be_a ParenExpressionNode
		expect(node[1][0]).to be_a AddNode
		expect(node[1][0][0].str).to eq "b"
		expect(node[1][0][1].str).to eq "c"
	end

	it "paren expression 4" do
		r = Parser.new(
			"()"
			)
		token, ws = r.read_token_w()
		node, ws, err = r.parse_paren_expression_we(token)
		expect(ws[0]).to be_nil
	end
	it "paren expression 5" do
		r = Parser.new(
			"(\n"+
			"  )"
			)
		token, ws = r.read_token_w()
		node, ws, err = r.parse_paren_expression_we(token)
		expect(ws[0]).to be_nil
	end
	it "paren expression 6" do
		r = Parser.new(
			"(\n"+
			"    )"
			)
		token, ws = r.read_token_w()
		node, ws, err = r.parse_paren_expression_we(token)
		expect(err).to be_a InvalidIndentError
		expect(err.token.pos).to eq CharPos.new(6, 1, 4)
	end
	it "paren expression 7" do
		r = Parser.new(
			"(1,\n" +
			"  2)")
		token, ws = r.read_token_w()
		node, ws, err = r.parse_paren_expression_we(token)
		expect(ws[0]).to be_nil
	end
	it "paren expression 8" do
		r = Parser.new(
			"(1,\n" +
			"  2\n" + 
			"  )")
		token, ws = r.read_token_w()
		node, ws, err = r.parse_paren_expression_we(token)
		expect(ws[0]).to be_nil
	end
	it "paren expression 9" do
		r = Parser.new(
			"(1,\n" +
			"  (2,\n" +
			"    )\n" +
			"  2\n" +
			"  )")
		token, ws = r.read_token_w()
		node, ws, err = r.parse_paren_expression_we(token)
		expect(ws[0]).to be_nil
	end

	it "call 1" do
		r = Parser.new("aaa(bbb)(ccc, ddd)")
		token, ws = r.read_code_token_w()
		node, ws, err = r.parse_unsigned_factor_we(token)
		expect(node).to be_a CallNode
		expect(node[0]).to be_a CallNode
		expect(node[0][0].str).to eq "aaa"
		expect(node[0][1].str).to eq "bbb"
		expect(node[1].str).to eq "ccc"
		expect(node[2].str).to eq "ddd"
	end

	it "call 2" do
		r = Parser.new(
			"a\n" +
			"  ()"
			)
		token, ws = r.read_token_w()
		node, ws, err = r.parse_unsigned_factor_we(token)
		expect(node).to be_a NameNode
	end

	it "var decl 1" do
		r = Parser.new("a")
		token, ws = r.read_code_token_w()
		node, ws, err = r.parse_variable_declaration_we(token)
		expect(node).to be_a VariableDeclarationNode
		expect(node[0].str).to eq "a"
	end

	it "var decl 2" do
		r = Parser.new("a: Int")
		token, ws = r.read_code_token_w()
		node, ws, err = r.parse_variable_declaration_we(token)
		expect(node).to be_a VariableDeclarationNode
		expect(node[0].str).to eq "a"
		expect(node[1].str).to eq "Int"
	end

	it "var decl 3" do
		r = Parser.new(
			"a: Int")
		token, ws = r.read_token_w()
		node, ws, err = r.parse_variable_declaration_we(token)
		expect(ws[0]).to be_nil
	end
	it "var decl 4" do
		r = Parser.new(
			"a\n"+
			": Int")
		token, ws = r.read_token_w()
		node, ws, err = r.parse_variable_declaration_we(token)
		expect(node).to be_a VariableDeclarationNode
		expect(node.children.length).to eq 1
	end
	it "var decl 5" do
		r = Parser.new(
			"a:\n"+
			"Int")
		token, ws = r.read_token_w()
		node, ws, err = r.parse_variable_declaration_we(token)
		expect(err).to be_a InvalidNewlineError
		expect(err.token.str).to eq "Int"
	end

	it "multi var decl 1" do
		r = Parser.new("a: Int")
		token, ws = r.read_code_token_w()
		node, ws, err = r.parse_multiple_variable_declaration_we(token)
		expect(node).to be_a MultipleVariableDeclarationNode
		expect(node[0]).to be_a VariableDeclarationNode
	end

	it "multi var decl 2" do
		r = Parser.new("a: Int, b: Float, c: String")
		token, ws = r.read_code_token_w()
		node, ws, err = r.parse_multiple_variable_declaration_we(token)
		expect(node).to be_a MultipleVariableDeclarationNode
		expect(node[0]).to be_a VariableDeclarationNode
		expect(node[0][0].str).to eq "a"
		expect(node[0][1].str).to eq "Int"
		expect(node[1]).to be_a VariableDeclarationNode
		expect(node[1][0].str).to eq "b"
		expect(node[1][1].str).to eq "Float"
		expect(node[2]).to be_a VariableDeclarationNode
		expect(node[2][0].str).to eq "c"
		expect(node[2][1].str).to eq "String"
	end

	it "multi var decl 3" do
		r = Parser.new(
			"a: Int,\n" +
			"  b: Int")
		token, ws = r.read_token_w()
		node, ws, err = r.parse_multiple_variable_declaration_we(token)
		expect(ws[0]).to be_nil
	end
	it "multi var decl 4" do
		r = Parser.new(
			"a: Int\n" + 
			"  ,\n" +
			"  b: Int")
		token, ws = r.read_token_w()
		node, ws, err = r.parse_multiple_variable_declaration_we(token)
		expect(ws[0]).to be_nil
	end
	it "multi var decl 5" do
		r = Parser.new(
			"a: Int,\n" +
			"   b: Int")
		token, ws = r.read_token_w()
		node, ws, err = r.parse_multiple_variable_declaration_we(token)
		expect(err).to be_a InvalidIndentError
	end
	it "multi var decl 6" do
		r = Parser.new(
			"a: Int\n" + 
			"   ,\n" +
			"  b: Int")
		token, ws = r.read_token_w()
		node, ws, err = r.parse_multiple_variable_declaration_we(token)
		expect(node).to be_a MultipleVariableDeclarationNode
		expect(node.children.length).to eq 1
	end
	it "multi var decl 7" do
		r = Parser.new(
			"a: Int\n" + 
			"  ,\n" +
			"   b: Int")
		token, ws = r.read_token_w()
		node, ws, err = r.parse_multiple_variable_declaration_we(token)
		expect(err).to be_a InvalidIndentError
	end

	it "paren var decl 1" do
		r = Parser.new("()")
		token, ws = r.read_code_token_w()
		node, ws, err = r.parse_paren_variable_declaration_we(token)
		expect(node).to be_a ParenVariableDeclarationNode
		expect(node.children.length).to eq 0
	end

	it "paren var decl 2" do
		r = Parser.new("(a: Int)")
		token, ws = r.read_code_token_w()
		node, ws, err = r.parse_paren_variable_declaration_we(token)
		expect(node).to be_a ParenVariableDeclarationNode
		expect(node[0]).to be_a VariableDeclarationNode
	end

	it "paren var decl 3" do
		r = Parser.new("(a: Int, b: Float, c: String)")
		token, ws = r.read_code_token_w()
		node, ws, err = r.parse_paren_variable_declaration_we(token)
		expect(node).to be_a ParenVariableDeclarationNode
		expect(node[0]).to be_a VariableDeclarationNode
		expect(node[0][0].str).to eq "a"
		expect(node[0][1].str).to eq "Int"
		expect(node[1]).to be_a VariableDeclarationNode
		expect(node[1][0].str).to eq "b"
		expect(node[1][1].str).to eq "Float"
		expect(node[2]).to be_a VariableDeclarationNode
		expect(node[2][0].str).to eq "c"
		expect(node[2][1].str).to eq "String"
	end

	it "paren var decl 4" do
		r = Parser.new(
			"(a: Int,\n" +
			"  b: Int,\n" +
			"  )")
		token, ws = r.read_token_w()
		node, ws, err = r.parse_paren_variable_declaration_we(token)
		expect(ws[0]).to be_nil
	end
	it "paren var decl 5" do
		r = Parser.new(
			"(a: Int,\n" +
			"  b: Int\n" +
			")")
		token, ws = r.read_token_w()
		node, ws, err = r.parse_paren_variable_declaration_we(token)
		expect(err).to be_a InvalidIndentError
		expect(err.token.str).to eq ")"
	end
	it "paren var decl 6" do
		r = Parser.new(
			"(a: Int,\n" +
			"b: Int\n" +
			"  )")
		token, ws = r.read_token_w()
		node, ws, err = r.parse_paren_variable_declaration_we(token)
		expect(err).to be_a InvalidIndentError
	end

	it "assignment 1" do
		r = Parser.new("a = b")
		token, ws = r.read_code_token_w()
		node, equal, ws, err = r.parse_assignment_expression_we(token)
		expect(node).to be_a AssignmentNode
		expect(ws.length).to eq 0
	end

	it "assignment 2" do
		r = Parser.new(
			"a =")
		token, ws = r.read_code_token_w()
		node, equal, ws, err = r.parse_assignment_expression_we(token)
		expect(node).to be_nil
		expect(err).to be_a TokenError
	end

	it "assignment 3" do
		r = Parser.new(
			"a =\n" +
			"  b")
		token, ws = r.read_code_token_w()
		node, equal, ws, err = r.parse_assignment_expression_we(token)
		expect(node).to be_a AssignmentNode
		expect(ws.length).to eq 0
	end

	it "assignment 4" do
		r = Parser.new(
			"a =\n" +
			"    b")
		token, ws = r.read_code_token_w()
		node, equal, ws, err = r.parse_assignment_expression_we(token)
		expect(err).to be_a InvalidIndentError
		expect(err.token.str).to eq "b"
	end

	it "assignment 5" do
		r = Parser.new(
			"a\n" +
			"  =\n" +
			"    b")
		token, ws = r.read_code_token_w()
		node, equal, ws, err = r.parse_assignment_expression_we(token)
		expect(node).to be_a AssignmentNode
		expect(ws.length).to eq 0
	end

	it "assignment 6" do
		r = Parser.new(
			"(a, b)\n" +
			"  =\n" +
			"    (c, d)")
		token, ws = r.read_code_token_w()
		node, equal, ws, err = r.parse_assignment_expression_we(token)
		expect(node).to be_a AssignmentNode
		expect(ws.length).to eq 0
	end	

	it "assignment 7" do
		r = Parser.new(
			"a\n" +
			"  =\n" +
			"  b")
		token, ws = r.read_code_token_w()
		node, equal, ws, err = r.parse_assignment_expression_we(token)
		expect(err).to be_a InvalidIndentError
		expect(err.token.str).to eq "b"
	end

	it "assignment 8" do
		r = Parser.new("aa = bb")
		token, ws = r.read_code_token_w()
		node, equal, ws, err = r.parse_assignment_expression_we(token)
		expect(node).to be_a AssignmentNode
		expect(node[0]).to be_a NameNode
		expect(node[0].str).to eq "aa"
		expect(node[1]).to be_a NameNode
		expect(node[1].str).to eq "bb"

		expect(r.token_reader.pos).to eq CharPos.new(7, 0, 7)
		token, ws = r.read_code_token_w()
		expect(token).to be_a EndToken
	end

	it "assignment 9" do
		r = Parser.new("aa = bb\n")
		token, ws = r.read_code_token_w()
		node, equal, ws, err = r.parse_assignment_expression_we(token)
		expect(node).to be_a AssignmentNode
		expect(node[0]).to be_a NameNode
		expect(node[0].str).to eq "aa"
		expect(node[1]).to be_a NameNode
		expect(node[1].str).to eq "bb"

		expect(r.token_reader.pos).to eq CharPos.new(7, 0, 7)
		token, ws = r.token_reader.read_token_w()
		expect(token).to be_a NewlineToken
		token, ws = r.token_reader.read_token_w()
		expect(token).to be_a EndToken
	end

	it "assignment 10" do
		r = Parser.new("aa = bb\n\n")
		token, ws = r.read_code_token_w()
		node, equal, ws, err = r.parse_assignment_expression_we(token)
		expect(node).to be_a AssignmentNode
		expect(node[0]).to be_a NameNode
		expect(node[0].str).to eq "aa"
		expect(node[1]).to be_a NameNode
		expect(node[1].str).to eq "bb"

		expect(r.token_reader.pos).to eq CharPos.new(7, 0, 7)
		token, ws = r.token_reader.read_token_w()
		expect(token).to be_a NewlineToken
		token, ws = r.token_reader.read_token_w()
		expect(token).to be_a NewlineToken
		token, ws = r.token_reader.read_token_w()
		expect(token).to be_a EndToken
	end

	it "assignment 11" do
		r = Parser.new("aa = cc\n\t\n")
		token, ws = r.read_code_token_w()
		node, equal, ws, err = r.parse_assignment_expression_we(token)
		expect(node).to be_a AssignmentNode

		expect(r.token_reader.pos).to eq CharPos.new(7, 0, 7)
	end

	it "func def" do
		r = Parser.new("func aaa(bbb: Int)-> Float")
		token, ws = r.read_code_token_w()
		node, ws, err = r.parse_func_statement_we(token)
		expect(node).to be_a FunctionDefinitionNode
		expect(node.name.str).to eq "aaa"
		expect(node.args[0].name.str).to eq "bbb"
		expect(node.args[0].type.str).to eq "Int" 
		expect(node.ret.str).to eq "Float"
	end

	it "statements 1" do
		r = Parser.new(
			"1 + 2 \n" +
			"  a * b"
			)
		token, ws = r.read_code_token_w()
		node, ws, err = r.parse_expression_we(token)

		expect(node).to be_a AddNode
		expect(node[0].value).to eq 1
		expect(node[1].value).to eq 2
		expect(r.token_reader.pos).to eq CharPos.new(5, 0, 5)

		space_tokens, ws = r.read_space_tokens_w()
		expect(space_tokens.length).to eq 3
		expect(space_tokens[0].str).to eq " "
		expect(space_tokens[1].str).to eq "\n"
		expect(space_tokens[2].str).to eq "  "

		token, ws = r.read_code_token_w()
		expect(token.str).to eq "a"
		node, ws, err = r.parse_expression_we(token)
		expect(node).to be_a MultiplyNode
		expect(node[0].str).to eq "a"
		expect(node[1].str).to eq "b"
	end

	it "statements 2" do
		r = Parser.new(
			"  // aaa\n" +
			"/* bbb\n" +
			"*/  a"
			)
		space_tokens, ws = r.read_space_tokens_w()
		expect(space_tokens[0].str).to eq "  "
		expect(space_tokens[1].str).to eq "// aaa"
		expect(space_tokens[2].str).to eq "\n"
		expect(space_tokens[3].str).to eq "/* bbb\n*/"
		expect(space_tokens[4].str).to eq "  "
		expect(space_tokens[4].end_pos).to eq CharPos.new(20, 2, 4)

		token, ws = r.read_code_token_w()
		expect(token.str).to eq "a"
		node, ws, err = r.parse_expression_we(token)
		expect(node).to be_a NameNode
		expect(node.str).to eq "a"
	end

	it "statements 3" do
		r = Parser.new(
			"a = b\n" +
			"c = d"
			)
		token, ws = r.read_code_token_w()
		node, equal, ws, err = r.parse_assignment_expression_we(token)
		expect(node).to be_a AssignmentNode
		expect(node[0].str).to eq "a"
		expect(node[1].str).to eq "b"
		expect(r.token_reader.pos).to eq CharPos.new(5, 0, 5)

		token, ws = r.read_code_token_w()
		node, equal, ws, err = r.parse_assignment_expression_we(token)
		expect(node).to be_a AssignmentNode
		expect(node[0].str).to eq "c"
		expect(node[1].str).to eq "d"
		expect(r.token_reader.pos).to eq CharPos.new(11, 1, 5)
	end

	it "func 1" do
		r = Parser.new(
			"func f()-> Void\n"
			)
		token, ws = r.read_code_token_w()
		node, ws, err = r.parse_func_statement_we(token)
		expect(ws.length).to eq 0
		expect(node).to be_a FunctionDefinitionNode
		expect(node.name).to be_a NameNode
		expect(node.args.length).to eq 0
		expect(node.ret).to be_a TypeNode
		expect(node.body.length).to eq 0
	end

	it "func 2" do
		r = Parser.new(
			"func f(a: Int)-> Float\n" +
			"  a + 1"
			)
		token, ws = r.read_code_token_w()
		node, ws, err = r.parse_func_statement_we(token)
		expect(ws.length).to eq 0
		expect(node).to be_a FunctionDefinitionNode
		expect(node.args[0]).to be_a VariableDeclarationNode
		expect(node.args[0][0]).to be_a NameNode
		expect(node.args[0][0].str).to eq "a"
		expect(node.args[0][1]).to be_a TypeNode
		expect(node.args[0][1].str).to eq "Int"
		expect(node.ret).to be_a TypeNode
		expect(node.ret.str).to eq "Float"
		expect(node.body.length).to eq 1
		expect(node.body[0]).to be_a AddNode
	end

	it "func 3" do
		r = Parser.new(
			"func\n" + 
			"f()-> Void\n"
			)
		token, ws = r.read_code_token_w()
		node, ws, err = r.parse_func_statement_we(token)
		expect(err).to be_a InvalidNewlineError
		expect(err.token.str).to eq "f"
	end

	it "func 4" do
		r = Parser.new(
			"func f(\n" +
			"  a: Int)-> Void\n")
		token, ws = r.read_code_token_w()
		node, ws, err = r.parse_func_statement_we(token)
		expect(ws.length).to eq 0
		expect(node).to be_a FunctionDefinitionNode
		expect(node.name).to be_a NameNode
		expect(node.args.length).to eq 1
		expect(node.ret).to be_a TypeNode
		expect(node.body.length).to eq 0
	end

	it "func 5" do
		r = Parser.new(
			"func f(\n" +
			"   a: Int)-> Void\n")
		token, ws = r.read_code_token_w()
		node, ws, err = r.parse_func_statement_we(token)
		expect(err).to be_a InvalidIndentError
	end

	it "func 6" do
		r = Parser.new(
			"func f(\n" +
			"  a: Int\n"+
			"  )-> Void\n")
		token, ws = r.read_code_token_w()
		node, ws, err = r.parse_func_statement_we(token)
		expect(ws.length).to eq 0
	end

	it "func 7" do
		r = Parser.new(
			"func f(\n" +
			"  a: Int\n"+
			"  )\n" + 
			"  -> Void\n")
		token, ws = r.read_code_token_w()
		node, ws, err = r.parse_func_statement_we(token)
		expect(err).to be_a InvalidNewlineError
		expect(err.token.str).to eq "->"
	end

	it "func 8" do
		r = Parser.new(
			"func f(\n" +
			"  a: Int)->\n"+
			"  Void\n")
		token, ws = r.read_code_token_w()
		node, ws, err = r.parse_func_statement_we(token)
		expect(err).to be_a InvalidNewlineError
		expect(err.token.str).to eq "Void"
	end

	it "func 9" do
		r = Parser.new(
			"func f(a: Int)-> Void\n" +
			"  a + 1"
		)
		token, ws = r.read_code_token_w()
		node, ws, err = r.parse_func_statement_we(token)
		expect(ws.length).to eq 0
	end

	it "func 10" do
		r = Parser.new(
			"func f(a: Int)-> Void\n" +
			"    a + 1"
		)
		token, ws = r.read_code_token_w()
		node, ws, err = r.parse_func_statement_we(token)
		expect(ws.length).to eq 1
		expect(ws[0]).to be_a InvalidIndentError
	end

	it "func 11" do
		r = Parser.new(
			"func f(\n" +
			"  a: Int\n" +
			"  )-> Void\n" +
			"  a + 1"
		)
		token, ws = r.read_code_token_w()
		node, ws, err = r.parse_func_statement_we(token)
		expect(ws.length).to eq 0
	end

	it "func 12" do
		r = Parser.new(
			"func f(\n" +
			"  a: Int\n" +
			"  )-> Void\n" +
			"    a + 1"
		)
		token, ws = r.read_code_token_w()
		node, ws, err = r.parse_func_statement_we(token)
		expect(ws.length).to eq 1
		expect(ws[0]).to be_a InvalidIndentError
	end

	it "func 13" do
		r = Parser.new(
			"func f(\n" +
			"  a: Int\n" +
			"  )-> Void\n" +
			"\n" +
			"  a\n" +
			"\n" +
			"  b"
		)
		token, ws = r.read_code_token_w()
		node, ws, err = r.parse_func_statement_we(token)
		expect(ws.length).to eq 0
		expect(node.body.length).to eq 2
		expect(node.body[0].str).to eq "a"
		expect(node.body[1].str).to eq "b"
	end

	it "closure 1" do
		r = Parser.new(
			"(a: Int, b: Float)-> Void\n" +
			"  1 + 2\n" +
			"  3 * 4"
			)
		token, ws = r.read_code_token_w()
		node, arrow, ws, err = r.parse_closure_we(token)
		expect(ws.length).to eq 0
		expect(node.args.length).to eq 2
		expect(node.args[0][0].str).to eq "a"
		expect(node.args[0][1].str).to eq "Int"
		expect(node.args[1][0].str).to eq "b"
		expect(node.args[1][1].str).to eq "Float"
		expect(node.ret.str).to eq "Void"
		expect(node.body.length).to eq 2
		expect(node.body[0]).to be_a AddNode
		expect(node.body[1]).to be_a MultiplyNode
	end

	it "closure 2" do
		r = Parser.new(
			"(\n" + 
			"  a: Int,\n" +
			"  b: Float\n" +
			"  )-> Void\n" +
			"  1 + 2\n" +
			"  3 * 4"
			)
		token, ws = r.read_code_token_w()
		node, arrow, ws, err = r.parse_closure_we(token)
		expect(ws.length).to eq 0
		expect(node.args.length).to eq 2
		expect(node.args[0][0].str).to eq "a"
		expect(node.args[0][1].str).to eq "Int"
		expect(node.args[1][0].str).to eq "b"
		expect(node.args[1][1].str).to eq "Float"
		expect(node.ret.str).to eq "Void"
		expect(node.body.length).to eq 2
		expect(node.body[0]).to be_a AddNode
		expect(node.body[1]).to be_a MultiplyNode
	end

	it "closure 3" do
		r = Parser.new(
			"f(()-> Void\n" +
			"  )"
			)
		node, ws, err = r.parse_block_statement_we()
		expect(ws.length).to eq 0
		expect(node).to be_a BlockNode
		expect(node[0]).to be_a CallNode
		expect(node[0][1]).to be_a ClosureNode
		expect(node[0][1].body.length).to eq 0
	end

	it "closure 4" do
		r = Parser.new(
			"f(()-> Void\n" +
			"  a,\n" +
			"  ()-> Void\n" +
			"    b,\n" +
			"  ()-> Void\n" +
			"    c" +
			"  )"
			)
		node, ws, err = r.parse_block_statement_we()
		expect(ws.length).to eq 0
		expect(node).to be_a BlockNode
		expect(node[0]).to be_a CallNode
		expect(node[0][1]).to be_a ClosureNode
		expect(node[0][1].body[0].str).to eq "a"
		expect(node[0][2]).to be_a ClosureNode
		expect(node[0][2].body[0].str).to eq "b"
		expect(node[0][3]).to be_a ClosureNode
		expect(node[0][3].body[0].str).to eq "c"
	end

	it "closure 5" do
		r = Parser.new(
			"f(\n" + 
			"  ()-> Void\n" +
			"    a\n" +
			"  , ()-> Void\n" +
			"    b\n" +
			"  , ()-> Void\n" +
			"    c" +
			"  )"
			)
		node, ws, err = r.parse_block_statement_we()
		expect(ws.length).to eq 0
		expect(node).to be_a BlockNode
		expect(node[0]).to be_a CallNode
		expect(node[0][1]).to be_a ClosureNode
		expect(node[0][1].body[0].str).to eq "a"
		expect(node[0][2]).to be_a ClosureNode
		expect(node[0][2].body[0].str).to eq "b"
		expect(node[0][3]).to be_a ClosureNode
		expect(node[0][3].body[0].str).to eq "c"
	end

	it "closure 6" do
		r = Parser.new(
			"()->\n" +
			"  a"
			)

		node, ws, err = r.parse_block_statement_we()
		expect(ws.length).to eq 0
		expect(node).to be_a BlockNode
		expect(node[0]).to be_a ClosureNode
		expect(node[0].ret).to be_nil
		expect(node[0].body[0].str).to eq "a"
	end

	it "closure 7" do
		r = Parser.new(
			"((a)->\n" + 
			"  return a\n" +
			"  )(1)"
			)
		node, ws, err = r.parse_block_statement_we()
		expect(ws.length).to eq 0
		expect(node).to be_a BlockNode
		expect(node.children.length).to eq 1
		expect(node[0]).to be_a CallNode
		expect(node[0][0]).to be_a ParenExpressionNode
		expect(node[0][0][0]).to be_a ClosureNode
		expect(node[0][1]).to be_a IntLiteralNode
	end

	it "return 1" do
		r = Parser.new(
			"return 1 + 2")
		token, ws = r.read_token_w()
		node, ws, err = r.parse_return_statement_we(token)
		expect(ws.length).to eq 0
		expect(node).to be_a ReturnNode
		expect(node[0]).to be_a AddNode
	end

	it "block 1" do
		r = Parser.new(
			"a\n" +
			"b")
		node, ws, err = r.parse_block_statement_we()
		expect(node.children.length).to eq 2
		expect(node[0]).to be_a NameNode
		expect(node[0].str).to eq "a"
		expect(node[1]).to be_a NameNode
		expect(node[1].str).to eq "b"
		expect(ws.length).to eq 0
	end

	it "block 2" do
		r = Parser.new(
			"a b\n" +
			"c"
			)
		node, ws, err = r.parse_block_statement_we()
		expect(node.children.length).to eq 3
		expect(node[0]).to be_a NameNode
		expect(node[0].str).to eq "a"
		expect(node[1]).to be_a NameNode
		expect(node[1].str).to eq "b"
		expect(node[2]).to be_a NameNode
		expect(node[2].str).to eq "c"
		expect(ws.length).to eq 1
		expect(ws[0]).to be_a NeedsNewlineError
	end

	it "block 3" do
		r = Parser.new(
			"a\n" +
			"b,\n" +
			"c")
		node, ws, err = r.parse_block_statement_we()
		expect(node.children.length).to eq 2
		expect(node[0]).to be_a NameNode
		expect(node[0].str).to eq "a"
		expect(node[1]).to be_a NameNode
		expect(node[1].str).to eq "b"
		expect(ws.length).to eq 0
		expect(r.token_reader.pos).to eq CharPos.new(3, 1, 1)
	end

	it "block 4" do
		r = Parser.new(
			"  a\n" +
			"  b"
			)
		r.indent_state = IndentState.new(0, true)
		node, ws, err = r.parse_block_statement_we()
		expect(node.children.length).to eq 2
		expect(node[0]).to be_a NameNode
		expect(node[0].str).to eq "a"
		expect(node[1]).to be_a NameNode
		expect(node[1].str).to eq "b"
		expect(ws.length).to eq 0
	end

	it "block 5" do
		r = Parser.new(
			"  a\n" +
			"    b"
			)
		r.indent_state = IndentState.new(0, true)
		node, ws, err = r.parse_block_statement_we()
		expect(node.children.length).to eq 2
		expect(node[0]).to be_a NameNode
		expect(node[0].str).to eq "a"
		expect(node[1]).to be_a NameNode
		expect(node[1].str).to eq "b"
		expect(ws.length).to eq 1
		expect(ws[0]).to be_a InvalidIndentError
	end

	it "block 6" do
		r = Parser.new(
			"func f(a: Int)-> Void\n" +
			"  a\n" +
			"func g(b: Int)-> Void\n" +
			"  b\n")
		node, ws, err = r.parse_block_statement_we()
		expect(ws.length).to eq 0
	end

	it "block 7" do
		r = Parser.new(
			"func f(\n" +
			"  a: Int\n" +
			"  )-> Void\n"
			)
		node, ws, err = r.parse_block_statement_we()
		expect(ws.length).to eq 0

		expect(node[0]).to be_a FunctionDefinitionNode
		expect(node[0].body.length).to eq 0
	end

	it "block 8" do
		r = Parser.new(
			"func f(\n" +
			"  a: Int\n" +
			"  )-> Void\n" +
			"  1\n" +
			"  2\n" +
			"\n" +
			"func g()-> Void\n" +
			"\n" +
			"  3\n" +
			"  4"
			)
		node, ws, err = r.parse_block_statement_we()
		expect(ws.length).to eq 0

		expect(node[0]).to be_a FunctionDefinitionNode
		expect(node[0].body.length).to eq 2
		expect(node[1]).to be_a FunctionDefinitionNode
		expect(node[1].body.length).to eq 2
	end

	it "block 9" do
		r = Parser.new(
			"1 + 2\n" +
			"3 * 4")
		node, ws, err = r.parse_block_statement_we()
		expect(ws.length).to eq 0
		expect(node.children.length).to eq 2
		expect(node[0]).to be_a AddNode
		expect(node[1]).to be_a MultiplyNode
	end

	it "block 10" do
		r = Parser.new(
			"1\n" +
			"  + 2\n")
		node, ws, err = r.parse_block_statement_we()
		expect(ws.length).to eq 0
	end

	it "block 11" do
		r = Parser.new(
			"1\n" +
			"  + 2\n" +
			"3 * 4")
		node, ws, err = r.parse_block_statement_we()
		expect(ws.length).to eq 0
	end

	it "block 12" do
		r = Parser.new(
			"1\n" +
			"2\n" +
			"3,"
			)
		node, ws, err = r.parse_block_statement_we()
		expect(ws.length).to eq 0
	end

	it "block 13" do
		r = Parser.new(
			"func f(a: Int, b: Int)-> Int\n" +
			"  return a + b + 1")
		node, ws, err = r.parse_block_statement_we()
		expect(ws.length).to eq 0
		expect(node).to be_a BlockNode
		expect(node[0]).to be_a FunctionDefinitionNode
		expect(node[0].body[0]).to be_a ReturnNode
		expect(node[0].body[0][0]).to be_a AddNode
		expect(node[0].body[0][0][0]).to be_a AddNode
		expect(node[0].body[0][0][1]).to be_a IntLiteralNode
		expect(node[0].body[0][0][1].value).to eq 1
		expect(node[0].body[0][0][0][0]).to be_a NameNode
		expect(node[0].body[0][0][0][0].str).to eq "a"
		expect(node[0].body[0][0][0][1]).to be_a NameNode
		expect(node[0].body[0][0][0][1].str).to eq "b"
	end

end