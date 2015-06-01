require "./env"

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
	def inspect
		pr = NodePrinter.new()
		print_with_printer(pr)
		return pr.buf
	end
	def to_s
		parts = []

		parts.push(
			"tokens=[" + tokens.map {|t| t.to_s }.join(", ") + "]"
			)
		parts.push("child=#{children.length}")
		if token = tokens.first
			parts.push("pos=#{token.pos}")
		end
		return "#{self.class}(" + parts.join(", ") + ")"		
	end
	def print_with_printer(pr)
		parts = []
		parts.push(
			"tokens=[" + tokens.map {|t| t.inspect }.join(", ") + "]"
			)
		pr.print("#{self.class}(" + parts.join(", ") + ")")
		pr.push()
		@children.each { |c| c.print_with_printer(pr) }
		pr.pop()
	end
end

class NameNode < Node
	attr_reader :token
	def initialize(token)
		@token = token
		super([token], [])
	end
	def with_children()
		return NameNode.new(token)
	end
	def str
		token.str
	end
end
class TypeNode < Node
	attr_reader :token
	def initialize(token)
		@token = token
		super([token], [])
	end
	def with_children()
		return NameNode.new(token)
	end
	def str
		token.str
	end
end
class IntLiteralNode < Node
	attr_reader :token
	def initialize(token)
		@token = token
		super([token], [])
	end
	def value
		token.value
	end
end
class FloatLiteralNode < Node
	attr_reader :token
	def initialize(token)
		@token = token
		super([token], [])
	end
	def value
		token.value
	end
end
class CallNode < Node
	attr_reader :function
	attr_reader :left_paren_token
	attr_reader :comma_tokens
	attr_reader :right_paren_token
	attr_reader :args
	def initialize(
		function,
		left_paren_token,
		comma_tokens,
		right_paren_token,
		args)
		@function = function
		@left_paren_token = left_paren_token
		@comma_tokens = comma_tokens
		@right_paren_token = right_paren_token
		@args = args

		tokens = []
		tokens.push(left_paren_token)
		tokens += comma_tokens
		tokens.push(right_paren_token)

		children = []
		children.push(function)
		children += args

		super(tokens, children)
	end
	def with_children(function, args)
		return CallNode.new(
			function,
			left_paren_token,
			comma_tokens,
			right_paren_token,
			args
			)
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
	attr_reader :comma_tokens
	attr_reader :expressions
	def initialize(
		comma_tokens,
		expressions)
		@comma_tokens = comma_tokens
		@expressions = expressions

		super(comma_tokens, expressions)
	end
end
class ParenExpressionNode < Node
	attr_reader :left_paren_token
	attr_reader :comma_tokens
	attr_reader :right_paren_token
	attr_reader :expressions
	def initialize(
		left_paren_token,
		comma_tokens,
		right_paren_token,
		expressions)
		@left_paren_token = left_paren_token
		@comma_tokens = comma_tokens
		@right_paren_token = right_paren_token
		@expressions = expressions

		tokens = []
		tokens.push(left_paren_token)
		tokens += comma_tokens
		tokens.push(right_paren_token)
		
		children = []
		children += expressions

		super(tokens, children)
	end
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
	def with_children(name, type)
		return VariableDeclarationNode.new(name, colon_token, type)
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
		if ret
			children.push(ret)
		end
		children += body

		super(tokens, children)
	end
	def with_children(args, ret, body)
		return ClosureNode.new(
			left_paren_token,
			comma_tokens,
			right_paren_token,
			args,
			arrow_token,
			ret,
			body)
	end
	def generate_local_env(env)
		name_table = env.name_table.clone()
		for arg in args
			name_table[arg.name.str] = arg.name
		end
		return env.make_child().with_name_table(name_table)
	end
end
class ReturnNode < Node
	attr_reader :return_token
	attr_reader :expression
	def initialize(return_token, expression)
		@return_token = return_token
		@expression = expression

		children = []
		if expression
			children.push(expression)
		end
		super([return_token], children)
	end
	def with_children(expression)
		return ReturnNode.new(return_token, expression)
	end
end
class BlockNode < Node
	attr_reader :statements
	def initialize(statements)
		@statements = statements
		super([], statements)
	end
end

