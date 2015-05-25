require "./parser_error"
require "./indent_state"
require "./token_reader"
require "./node"

class Parser
	attr_reader :token_reader
	attr_accessor :indent_state
	def initialize(source)
		@token_reader = TokenReader.new(source)
		@indent_state = IndentState.new(0, false)
	end
	def nest_indent()
		old = @indent_state
		@indent_state = old.nest()
		return old
	end
	def get_indent_len(level=nil)
		if level == nil
			level = @indent_state.level
		end
		return level * 2
	end
	def check_token_indent(token)
		valid_len = get_indent_len(indent_state.level)
		if token.pos.column != valid_len
			return [InvalidIndentError.new(token, valid_len)]
		end
		return []
	end
	def check_token_no_newline(begin_pos, token)
		warns = []
		if token.pos.line != begin_pos.line
			warns.push(InvalidNewlineError.new(token))
		end
		return warns
	end
	def check_token_indent2(token)
		valid_len = get_indent_len(indent_state.level)
		if token.pos.column != valid_len
			return InvalidIndentError.new(token, valid_len)
		end
		return nil
	end
	def check_token_hanging(begin_pos, token)
		if begin_pos.line != token.pos.line
			@indent_state = @indent_state.set_hanging(true)
			return check_token_indent2(token)
		end
		return nil
	end
	def read_token_w()
		return token_reader.read_token_w()
	end
	def seek_to_pos(pos)
		token_reader.seek_to_pos(pos)
	end
	def warns_pop(warns, pop_warns)
		warns = warns.clone()
		warns_tail = warns[warns.length - pop_warns.length, pop_warns.length]
		if warns_tail != pop_warns
			raise "not match: warns_tail = #{warns_tail}, pop_warns = #{pop_warns}"
		end
		warns.pop(pop_warns.length)
		return warns
	end
	def read_space_tokens_w()
		tokens = []
		warns = []
		while true
			pos = token_reader.pos
			token, ws = read_token_w()
			warns += ws
			if token.is_comment || 
				token.is_a?(SpaceToken) ||
				token.is_a?(NewlineToken) ||
				token.is_a?(InvalidToken) ||
				token.is_a?(TabToken)

				tokens.push(token)
				if token.is_a?(TabToken)
					warns.push(TabIndentError.new(token))
				end
			else
				seek_to_pos(pos)
				return tokens, warns
			end
		end
	end
	def read_oneline_space_tokens_w()
		tokens = []
		warns = []
		while true
			pos = token_reader.pos
			token, ws = read_token_w()
			warns += ws
			if token.is_comment || 
				token.is_a?(SpaceToken) ||
				token.is_a?(InvalidToken) ||
				token.is_a?(TabToken)
				
				tokens.push(token)
				if token.is_a?(TabToken)
					warns.push(TabIndentError.new(token))
				end
			else
				seek_to_pos(pos)
				return tokens, warns
			end
		end
	end
	def read_eol_token_w()
		warns = []
		_, ws = read_oneline_space_tokens_w()
		warns += ws

		while true do
			pos = token_reader.pos
			token, ws = read_token_w()
			warns += ws
			if token.is_eol
				return token, warns
			else
				seek_to_pos(pos)
				token = token_reader.discard_to_eol()
				warns.push(TokenNotNewlineError.new(token))
			end
		end
	end
	def read_code_token_w()
		warns = []
		_, ws = read_space_tokens_w()
		warns += ws

		token, ws = read_token_w()
		warns += ws

		return token, warns
	end
	def read_oneline_code_token_w()
		warns = []
		_, ws = read_oneline_space_tokens_w()
		warns += ws

		token, ws = read_token_w()
		warns += ws

		return token, warns
	end

	def parse_name_e(name_token)
		if not name_token.is_a?(KeywordToken)
			return nil, TokenNotKeywordError.new(name_token)
		else
			return NameNode.new(name_token), nil
		end
	end
	def parse_type_e(type_token)
		if not type_token.is_a?(KeywordToken)
			return nil, TokenNotKeywordError.new(type_token)
		else
			return TypeNode.new(type_token), nil
		end
	end
	def parse_element_we(element_token)
		if element_token.is_a?(IntNumberToken)
			return IntLiteralNode.new(element_token), [], nil
		elsif element_token.is_a?(FloatNumberToken)
			return FloatLiteralNode.new(element_token), [], nil
		elsif element_token.is_a?(LeftParenToken)
			closure_node, arrow_token, ws, err = parse_closure_we(element_token)
			if arrow_token
				if err
					return nil, [], err
				end
				return closure_node, ws, nil
			end

			paren_node, ws, err = parse_paren_expression_we(element_token)
			if err
				return nil, [], err
			end
			return paren_node, ws, nil

		elsif element_token.is_a?(KeywordToken)
			name_node, err = parse_name_e(element_token)
			if err
				return nil, [], err
			end
			return name_node, [], nil
		else
			return nil, [], TokenError.new(element_token)
		end
	end
	def parse_unsigned_factor_we(element_token)
		begin_indent = @indent_state
		begin_pos = token_reader.pos

		warns = []
		elem1, ws1, err = parse_element_we(element_token)
		if err
			return nil, [], err
		end
		warns += ws1

		while true
			token_begin_indent = @indent_state
			token_begin_pos = token_reader.pos

			token, ws2 = read_code_token_w()
			if token.is_a?(LeftParenToken)
				ws2 += check_token_no_newline(token_begin_pos, token)
				warns += ws2

				paren, ws3, err = parse_paren_expression_we(token)
				warns += ws3
				if err
					@indent_state = begin_indent
					seek_to_pos(begin_pos)
					return nil, [], err
				end
				elem1 = CallNode.new(elem1, paren)
			elsif token.is_a?(DotToken)
				if err = check_token_hanging(token_begin_pos, token)
					break
				end
				warns += ws2

				dot_token = token

				name_token, ws3 = read_code_token_w()
				warns += ws3

				member_name, err = parse_name_e(name_token)
				if err
					@indent_state = begin_indent
					seek_to_pos(begin_pos)
					return nil, [], err
				end

				elem1 = MemberNode.new(elem1, dot_token, member_name)
			else
				break
			end
		end

		@indent_state = token_begin_indent
		seek_to_pos(token_begin_pos)
		return elem1, warns, nil
	end
	def parse_factor_we(ufactor_token)
		begin_indent = @indent_state
		begin_pos = token_reader.pos

		warns = []
		if ufactor_token.is_term_operator
			operator_token = ufactor_token

			token_pos = token_reader.pos

			ufactor_token, ws1 = read_code_token_w()
			ws1 += check_token_no_newline(token_pos, ufactor_token)
			warns += ws1

			ufactor, ws2, err = parse_unsigned_factor_we(ufactor_token)
			if err
				@indent_state = begin_indent
				seek_to_pos(begin_pos)
				return nil, [], err
			end
			warns += ws2

			if operator_token.is_a?(PlusToken)
				return PlusSignNode.new(operator_token, ufactor), warns, nil
			else
				return MinusSignNode.new(operator_token, ufactor), warns, nil
			end
		else
			ufactor, ws, err = parse_unsigned_factor_we(ufactor_token)
			if err
				return nil, [], err
			end
			return ufactor, ws, nil
		end
	end
	def parse_term_we(factor_token)
		begin_indent = @indent_state
		begin_pos = token_reader.pos

		warns = []
		factor1, ws1, err = parse_factor_we(factor_token)
		if err
			return nil, [], err
		end
		warns += ws1

		while true
			token_begin_indent = @indent_state
			token_begin_pos = token_reader.pos

			operator_token, ws2 = read_code_token_w()
			if operator_token.is_factor_operator
				if err = check_token_hanging(token_begin_pos, operator_token)
					break
				end
				warns += ws2

				factor_token_begin_pos = token_reader.pos
				factor_token, ws3 = read_code_token_w()
				if err = check_token_hanging(factor_token_begin_pos, factor_token)
					@indent_state = begin_indent
					seek_to_pos(begin_pos)
					return nil, [], err
				end
				warns += ws3

				factor2, ws4, err = parse_factor_we(factor_token)
				if err
					@indent_state = begin_indent
					seek_to_pos(begin_pos)
					return nil, [], err
				end
				warns += ws4
				
				if operator_token.is_a?(StarToken)
					factor1 = MultiplyNode.new(operator_token, factor1, factor2)
				elsif operator_token.is_a?(SlashToken)
					factor1 = DivideNode.new(operator_token, factor1, factor2)
				else
					factor1 = DivModNode.new(operator_token, factor1, factor2)
				end
			else
				break
			end
		end

		@indent_state = token_begin_indent
		seek_to_pos(token_begin_pos)
		return factor1, warns, nil
	end
	def parse_polynomial_we(term_token)
		begin_indent = @indent_state
		begin_pos = token_reader.pos

		warns = []
		term1, ws1, err = parse_term_we(term_token)
		if err
			return nil, [], err
		end
		warns += ws1

		while true
			token_begin_indent = @indent_state
			token_begin_pos = token_reader.pos

			operator_token, ws2 = read_code_token_w()
			if operator_token.is_term_operator
				if err = check_token_hanging(token_begin_pos, operator_token)
					break
				end
				warns += ws2

				term_token_begin_pos = token_reader.pos
				term_token, ws3 = read_code_token_w()
				if err = check_token_hanging(term_token_begin_pos, term_token)
					@indent_state = begin_indent
					seek_to_pos(begin_pos)
					return nil, [], err
				end
				warns += ws3

				term2, ws4, err = parse_term_we(term_token)
				if err
					@indent_state = begin_indent
					seek_to_pos(begin_pos)
					return nil, [], err
				end
				warns += ws4

				if operator_token.is_a?(PlusToken)
					term1 = AddNode.new(operator_token, term1, term2)
				else
					term1 = SubtractNode.new(operator_token, term1, term2)
				end
			else
				break
			end
		end

		@indent_state = token_begin_indent
		seek_to_pos(token_begin_pos)
		return term1, warns, nil
	end
	def parse_expression_we(token)
		warns = []
		poly, ws1, err = parse_polynomial_we(token)
		if err
			return nil, [], err
		end
		warns += ws1
		return poly, warns, nil
	end
	def parse_multiple_expression_we(exp_token)
		begin_indent = @indent_state
		begin_pos = token_reader.pos

		warns = []
		exp, ws1, err = parse_expression_we(exp_token)
		if err
			return nil, [], err
		end
		warns += ws1

		exps = [exp]
		comma_tokens = []
		while true
			token_begin_indent = @indent_state
			token_begin_pos = token_reader.pos

			comma_token, ws2 = read_code_token_w()
			if comma_token.is_a?(CommaToken)
				if err = check_token_hanging(token_begin_pos, comma_token)
					break
				end
				warns += ws2

				comma_tokens.push(comma_token)
				exp_token_begin_pos = token_reader.pos
				exp_token, ws3 = read_code_token_w()
				if err = check_token_hanging(exp_token_begin_pos, exp_token)
					@indent_state = begin_indent
					seek_to_pos(begin_pos)
					return nil, [], err
				end
				warns += ws3

				indent = nest_indent()
				exp, ws4, err = parse_expression_we(exp_token)
				if err
					@indent_state = begin_indent
					seek_to_pos(begin_pos)
					return nil, [], err
				end
				warns += ws4
				@indent_state = indent

				exps.push(exp)
			else
				break
			end
		end

		@indent_state = token_begin_indent
		seek_to_pos(token_begin_pos)
		return MultipleExpressionNode.new(comma_tokens, exps), warns, nil
	end

	def parse_paren_expression_we(left_paren_token)
		begin_indent = @indent_state
		begin_pos = token_reader.pos

		warns = []
		mexp_token_begin_pos = token_reader.pos
		mexp_token, ws1 = read_code_token_w()
		if err = check_token_hanging(mexp_token_begin_pos, mexp_token)
			@indent_state = begin_indent
			seek_to_pos(begin_pos)
			return nil, [], err
		end
		warns += ws1

		if mexp_token.is_a?(RightParenToken)
			right_paren_token = mexp_token
			return ParenExpressionNode.new([left_paren_token, right_paren_token], []), warns, nil
		else
			mexp, ws2, err = parse_multiple_expression_we(mexp_token)
			if err
				@indent_state = begin_indent
				seek_to_pos(begin_pos)
				return nil, [], err
			end
			warns += ws2

			pos = token_reader.pos()
			right_paren_token, ws3 = read_code_token_w()
			if not right_paren_token.is_a?(RightParenToken)
				@indent_state = begin_indent
				seek_to_pos(begin_pos)
				return nil, [], TokenNotRightParenError.new(right_paren_token)
			end
			warns += ws3

			if err = check_token_hanging(pos, right_paren_token)
				@indent_state = begin_indent
				seek_to_pos(begin_pos)
				return nil, [], err
			end

			tokens = [left_paren_token] + mexp.tokens + [right_paren_token]
			return ParenExpressionNode.new(tokens, mexp.children), warns, nil
		end
	end
	def parse_variable_declaration_we(var_name_token)
		begin_indent = @indent_state
		begin_pos = token_reader.pos

		warns = []
		var_name, err = parse_name_e(var_name_token)
		if err
			return nil, [], err
		end

		pos = token_reader.pos
		colon_token, ws1 = read_code_token_w()
		if colon_token.is_a?(ColonToken)
			ws1 += check_token_no_newline(pos, colon_token)
			warns += ws1
		else
			seek_to_pos(pos)
			return VariableDeclarationNode.new(var_name, nil, nil), warns, nil
		end

		type_token_begin_pos = token_reader.pos
		type_token, ws2 = read_code_token_w()
		ws2 += check_token_no_newline(type_token_begin_pos, type_token)
		warns += ws2

		type, err = parse_type_e(type_token)
		if err
			@indent_state = begin_indent
			seek_to_pos(begin_pos)
			return nil, [], err
		end
		return VariableDeclarationNode.new(var_name, colon_token, type), warns, nil
	end
	def parse_multiple_variable_declaration_we(var_decl_token)
		begin_indent = @indent_state
		begin_pos = token_reader.pos

		warns = []
		var_decl, ws1, err = parse_variable_declaration_we(var_decl_token)
		if err
			return nil, [], err
		end
		warns += ws1
		var_decls = [var_decl]
		comma_tokens = []

		while true
			token_begin_indent = @indent_state
			token_begin_pos = token_reader.pos
			comma_token, ws2 = read_code_token_w()
			if comma_token.is_a?(CommaToken)
				if err = check_token_hanging(token_begin_pos, comma_token)
					break
				end
				warns += ws2

				comma_tokens.push(comma_token)

				var_decl_token_begin_pos = token_reader.pos
				var_decl_token, ws3 = read_code_token_w()
				if err = check_token_hanging(var_decl_token_begin_pos, var_decl_token)
					@indent_state = begin_indent
					seek_to_pos(begin_pos)
					return nil, [], err
				end
				warns += ws3

				indent = nest_indent()
				var_decl, ws4, err = parse_variable_declaration_we(var_decl_token)
				if err
					@indent_state = begin_indent
					seek_to_pos(begin_pos)
					return nil, [], err
				end
				warns += ws4
				@indent_state = indent

				var_decls.push(var_decl)
			else
				break
			end
		end

		@indent_state = token_begin_indent
		seek_to_pos(token_begin_pos)
		return MultipleVariableDeclarationNode.new(comma_tokens, var_decls), warns, nil
	end

	def parse_paren_variable_declaration_we(left_paren_token)
		begin_indent = @indent_state
		begin_pos = token_reader.pos

		warns = []
		mvar_decl_token_begin_pos = token_reader.pos
		mvar_decl_token, ws1 = read_code_token_w()
		if err = check_token_hanging(mvar_decl_token_begin_pos, mvar_decl_token)
			@indent_state = begin_indent
			seek_to_pos(begin_pos)
			return nil, [], err
		end
		warns += ws1

		if mvar_decl_token.is_a?(RightParenToken)
			right_paren_token = mvar_decl_token
			return ParenVariableDeclarationNode.new(
				[left_paren_token, right_paren_token], []), warns, nil
		else
			mvar_decl, ws2, err = parse_multiple_variable_declaration_we(mvar_decl_token)
			if err
				@indent_state = begin_indent
				seek_to_pos(begin_pos)
				return nil, [], err
			end
			warns += ws2
			pos = token_reader.pos
			right_paren_token, ws3 = read_code_token_w()			
			if not right_paren_token.is_a?(RightParenToken)
				@indent_state = begin_indent
				seek_to_pos(begin_pos)
				return nil, [], TokenNotRightParenError.new(right_paren_token)
			end
			warns += ws3

			if err = check_token_hanging(pos, right_paren_token)
				@indent_state = begin_indent
				seek_to_pos(begin_pos)
				return nil, [], err
			end

			tokens = [left_paren_token] + mvar_decl.tokens + [right_paren_token]
			return ParenVariableDeclarationNode.new(tokens, mvar_decl.children), warns, nil
		end
	end
	# ret: node, equal_token, warns, err
	def parse_assignment_expression_we(exp_token)
		begin_indent = @indent_state
		begin_pos = token_reader.pos

		warns = []

		exp1, ws1, err = parse_expression_we(exp_token)
		if err
			return nil, nil, [], err
		end
		warns += ws1

		equal_token_begin_pos = token_reader.pos
		equal_token, ws2 = read_code_token_w()
		if not equal_token.is_a?(EqualToken)
			@indent_state = begin_indent
			seek_to_pos(begin_pos)
			return nil, nil, [], TokenNotEqualError.new(equal_token)
		end
		warns += ws2

		nest_indent()
		if err = check_token_hanging(equal_token_begin_pos, equal_token)
			@indent_state = begin_indent
			seek_to_pos(begin_pos)
			return nil, equal_token, [], err
		end

		nest_indent()
		exp_token_begin_pos = token_reader.pos
		exp_token, ws3 = read_code_token_w()
		if err = check_token_hanging(exp_token_begin_pos, exp_token)
			@indent_state = begin_indent
			seek_to_pos(begin_pos)
			return nil, equal_token, [], err
		end
		warns += ws3

		exp2, ws4, err = parse_expression_we(exp_token)
		if err
			@indent_state = begin_indent
			seek_to_pos(begin_pos)
			return nil, equal_token, [], err
		end
		warns += ws4

		return AssignmentNode.new(exp1, equal_token, exp2), equal_token, warns, nil
	end
	def parse_func_statement_we(func_keyword_token)
		begin_indent = @indent_state
		begin_pos = token_reader.pos

		warns = []

		func_name_token_begin_pos = token_reader.pos
		func_name_token, ws1 = read_code_token_w()
		ws1 += check_token_no_newline(func_name_token_begin_pos, func_name_token)
		warns += ws1

		func_name, err = parse_name_e(func_name_token)
		if err
			@indent_state = begin_indent
			seek_to_pos(begin_pos)
			return nil, [], err
		end

		left_paren_token_begin_pos = token_reader.pos
		left_paren_token, ws2 = read_code_token_w()
		if not left_paren_token.is_a?(LeftParenToken)
			@indent_state = begin_indent
			seek_to_pos(begin_pos)
			return nil, [], TokenNotLeftParenError.new(left_paren_token)
		end
		ws2 += check_token_no_newline(left_paren_token_begin_pos, left_paren_token)
		warns += ws2

		var_decl, ws3, err = parse_paren_variable_declaration_we(left_paren_token)
		if err
			@indent_state = begin_indent
			seek_to_pos(begin_pos)
			return nil, [], err
		end
		warns += ws3

		arrow_token_begin_pos = token_reader.pos
		arrow_token, ws4 = read_code_token_w()
		if not arrow_token.is_a?(ArrowToken)
			@indent_state = begin_indent
			seek_to_pos(pos)
			return nil, [], TokenNotArrowError.new(arrow_token)
		end
		ws4 += check_token_no_newline(arrow_token_begin_pos, arrow_token)
		warns += ws4

		ret_type_token_begin_pos = token_reader.pos
		ret_type_token, ws5 = read_code_token_w()
		ws5 += check_token_no_newline(ret_type_token_begin_pos, ret_type_token)
		warns += ws5

		ret_type, err = parse_type_e(ret_type_token)
		if err
			@indent_state = begin_indent
			seek_to_pos(pos)
			return nil, [], err
		end

		eol_token, ws6 = read_eol_token_w()
		warns += ws6

		@indent_state = IndentState.new(begin_indent.level + 1, false)
		func_body, ws7, err = parse_block_statement_we()
		if err
			@indent_state = begin_indent
			seek_to_pos(pos)
			return nil, [], err
		end
		warns += ws7
		@indent_state = begin_indent
		
		return FunctionDefinitionNode.new(
			func_keyword_token, func_name, var_decl, ret_type,
			func_body), warns, nil
	end

	def parse_return_statement_we(return_token)
		begin_indent = @indent_state
		begin_pos = token_reader.pos

		warns = []

		exp_token_begin_pos = token_reader.pos
		exp_token, ws1 = read_code_token_w()
		ws1 += check_token_no_newline(exp_token_begin_pos, exp_token)
		warns += ws1
		exp, ws2, err = parse_expression_we(exp_token)
		if err
			@indent_state = begin_indent
			seek_to_pos(begin_pos)
			return nil, [], err
		end
		warns += ws2

		return ReturnNode.new(return_token, exp), warns, nil
	end

	# ret: node, arrow_token, warns, err
	def parse_closure_we(left_paren_token)
		begin_indent = @indent_state
		begin_pos = token_reader.pos

		warns = []

		var_decl, ws1, err = parse_paren_variable_declaration_we(left_paren_token)
		warns += ws1
		if err
			@indent_state = begin_indent
			seek_to_pos(begin_pos)
			return nil, nil, [], err
		end

		arrow_token_begin_pos = token_reader.pos
		arrow_token, ws2 = read_code_token_w()
		if not arrow_token.is_a?(ArrowToken)
			@indent_state = begin_indent
			seek_to_pos(begin_pos)
			return nil, nil, [], TokenNotArrowError.new(arrow_token)
		end
		ws2 += check_token_no_newline(arrow_token_begin_pos, arrow_token)
		warns += ws2

		ret_type_token_begin_pos = token_reader.pos
		ret_type_token, ws3 = read_oneline_code_token_w()
		if ret_type_token.is_eol
			# puts "ret type token is EOL: #{ret_type_token.inspect}"
			warns += ws3
			# 返り値定義の省略
			ret_type = nil
		else
			seek_to_pos(ret_type_token_begin_pos)
			ret_type_token, ws3 = read_code_token_w()

			# puts "ret type token is: #{ret_type_token.inspect}"
			ws3 += check_token_no_newline(ret_type_token_begin_pos, ret_type_token)
			warns += ws3
			ret_type, err = parse_type_e(ret_type_token)
			if err
				@indent_state = begin_indent
				seek_to_pos(begin_pos)
				return nil, arrow_token, [], err
			end
			eol_token, ws4 = read_eol_token_w()
			warns += ws4
		end

		@indent_state = IndentState.new(begin_indent.level + 1, false)
		body, ws5, err = parse_block_statement_we()
		if err
			@indent_state = begin_indent
			seek_to_pos(pos)
			return nil, arrow_token, [], err
		end
		warns += ws5
		@indent_state = begin_indent

		return ClosureNode.new(var_decl, ret_type, body), arrow_token, warns, nil
	end

	def parse_block_entry_statement_we(token)
		warns = []

		if token.is_a?(KeywordToken)
			case token.str
			when "func"
				func, ws1, err = parse_func_statement_we(token)
				if err
					return nil, [], err
				end
				warns += ws1
				return func, warns, nil
			when "return"
				retn, ws1, err = parse_return_statement_we(token)
				if err
					return nil, [], err
				end
				warns += ws1
				return retn, warns, nil
			end
		end

		assign, equal_token, ws1, err = parse_assignment_expression_we(token)
		if equal_token
			if err
				return nil, [], err
			end
			warns += ws1
			return assign, warns, nil
		end

		exp, ws1, err = parse_expression_we(token)
		if err
			return nil, [], err
		end

		warns += ws1
		return exp, warns, nil
	end

	def parse_block_statement_we()
		begin_indent = indent_state
		begin_pos = token_reader.pos

		block_indent = IndentState.new(begin_indent.level, false)

		warns = []
		statements = []

		prev_statement_end_pos = nil

		while true
			@indent_state = block_indent

			token_begin_pos = token_reader.pos
			token, ws1 = read_code_token_w()

			if token.pos.column < get_indent_len
				seek_to_pos(token_begin_pos)
				break
			end
			if prev_statement_end_pos && 
				prev_statement_end_pos.line == token.pos.line
				ws1.push(NeedsNewlineError.new(token))
			else
				ws1 += check_token_indent(token)
			end

			statement, ws2, err = parse_block_entry_statement_we(token)
			if err
				seek_to_pos(token_begin_pos)
				break
			end

			warns += ws1
			warns += ws2
			statements.push(statement)
			prev_statement_end_pos = token_reader.pos
		end

		@indent_state = begin_indent
		return BlockNode.new(statements), warns, nil
	end
end