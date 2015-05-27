class NodePrinter
	attr_reader :buf
	def initialize()
		@depth = 0
		@buf = ""
	end
	def write_indent()
		@depth.times { @buf += "  " }
	end
	def print(line)
		write_indent()
		@buf += line
		@buf += "\n"
	end
	def push()
		@depth += 1
	end
	def pop()
		@depth -= 1
	end
end

class Node
	attr_reader :tokens, :children
	def initialize(tokens, children)
		@tokens = tokens
		@children = children
	end
	def [](index)
		@children[index]
	end
	def inspect()
		pr = NodePrinter.new()
		print_with_printer(pr)
		return pr.buf
	end
	def to_s()
		return inspect()
	end
	def print_with_printer(pr)
		str = "#{self.class}"
		if @tokens
			str += "(#{@tokens})"
		end
		pr.print(str)
		pr.push()
		@children.each { |c| c.print_with_printer(pr) }
		pr.pop()
	end
end

class NameNode < Node
	def initialize(token)
		super([token], [])
	end
	def str
		tokens[0].str
	end
end
class TypeNode < Node
	def initialize(token)
		super([token], [])
	end
	def str
		tokens[0].str
	end
end
class IntLiteralNode < Node
	def initialize(token)
		super([token], [])
	end
	def value
		tokens[0].value
	end
end
class FloatLiteralNode < Node
	def initialize(token)
		super([token], [])
	end
	def value
		tokens[0].value
	end
end
class CallNode < Node
	def initialize(obj, paren_node)
		super(paren_node.tokens, [obj] + paren_node.children)
	end
end
class MemberNode < Node
	def initialize(obj, dot_token, member_name_node)
		super([dot_token], [obj, member_name_node])
	end
end

class AddNode < Node
	def initialize(token, left, right)
		super([token], [left, right])
	end
end
class SubtractNode < Node
	def initialize(token, left, right)
		super([token], [left, right])
	end
end
class MultiplyNode < Node
	def initialize(token, left, right)
		super([token], [left, right])
	end
end
class DivideNode < Node
	def initialize(token, left, right)
		super([token], [left, right])
	end
end
class DivModNode < Node
	def initialize(token, left, right)
		super([token], [left, right])
	end
end
class PlusSignNode < Node
	def initialize(token, term)
		super([token], [term])
	end
end
class MinusSignNode < Node
	def initialize(token, term)
		super([token], [term])
	end
end

class MultipleExpressionNode < Node
end
class ParenExpressionNode < Node
end

# typeは無い事がある
class VariableDeclarationNode < Node
	attr_reader :name
	attr_reader :colon_token
	attr_reader :type
	def initialize(name, colon_token, type)
		@name = name
		@colon_token = colon_token
		@type = type

		tokens = []
		children = []

		children.push(name)

		if type
			tokens.push(colon_token)
			children.push(type)
		end

		super(tokens, children)
	end
end
class MultipleVariableDeclarationNode < Node
	attr_reader :comma_tokens, :var_decls
	def initialize(comma_tokens, var_decls)
		@comma_tokens = comma_tokens
		@var_decls = var_decls
		super(comma_tokens, var_decls)
	end
end
class ParenVariableDeclarationNode < Node
	attr_reader :left_paren_token
	attr_reader :comma_tokens
	attr_reader :right_paren_token
	attr_reader :var_decls
	def initialize(
		left_paren_token, 
		comma_tokens,
		right_paren_token,
		var_decls)
		@left_paren_token = left_paren_token
		@right_paren_token = right_paren_token
		@comma_tokens = comma_tokens
		@var_decls = var_decls
		super([left_paren_token] + comma_tokens + [right_paren_token], var_decls)
	end
end


class AssignmentNode < Node
	def initialize(left_node, equal_token, right_node)
		super([equal_token], [left_node, right_node])
	end
end
class FunctionDefinitionNode < Node
	attr_reader :left_paren_token
	attr_reader :name
	attr_reader :comma_tokens
	attr_reader :right_paren_token
	attr_reader :args
	attr_reader :arrow_token
	attr_reader :ret
	attr_reader :body
	def initialize(
		func_token,
		name,
		left_paren_token,
		comma_tokens,
		right_paren_token,
		args,
		arrow_token,
		ret,
		body)

		@left_paren_token = left_paren_token
		@name = name
		@comma_tokens = comma_tokens
		@right_paren_token = right_paren_token
		@args = args
		@arrow_token = arrow_token
		@ret = ret
		@body = body

		tokens = []
		tokens.push(left_paren_token)
		tokens += comma_tokens
		tokens.push(right_paren_token)
		tokens.push(arrow_token)

		children = []
		children.push(name)
		children += args
		children.push(ret)
		children += body

		super(tokens, children)
	end
end
class ClosureNode < Node
	attr_reader :left_paren_token
	attr_reader :comma_tokens
	attr_reader :right_paren_token
	attr_reader :args
	attr_reader :arrow_token
	attr_reader :ret
	attr_reader :body
	def initialize(
		left_paren_token, 
		comma_tokens,
		right_paren_token,
		args,
		arrow_token,
		ret,
		body)
	
		@left_paren_token = left_paren_token
		@comma_tokens = comma_tokens
		@right_paren_token = right_paren_token
		@args = args
		@arrow_token = arrow_token
		@ret = ret
		@body = body

		tokens = []
		tokens.push(left_paren_token)
		tokens += comma_tokens
		tokens.push(right_paren_token)
		tokens.push(arrow_token)

		children = []
		children += args
		children.push(ret || [])
		children += body

		super(tokens, children)
	end
end
class ReturnNode < Node
	def initialize(return_token, exp)
		super([return_token], [exp])
	end
end
class BlockNode < Node
	attr_reader :statements
	def initialize(statements)
		@statements = statements
		super([], statements)
	end
end

