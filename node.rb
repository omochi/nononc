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
	attr_reader :name, :type
	def initialize(name_node, colon_token, type_node)
		@name = name_node
		@type = type_node

		tokens = []
		children = [name_node]

		if type_node
			tokens.push(colon_token)
			children.push(type_node)
		end

		super(tokens, children)
	end
end
class MultipleVariableDeclarationNode < Node
end
class ParenVariableDeclarationNode < Node
end


class AssignmentNode < Node
	def initialize(left_node, equal_token, right_node)
		super([equal_token], [left_node, right_node])
	end
end
class FunctionDefinitionNode < Node
	attr_reader :name, :args, :ret, :body
	def initialize(func_token, name, args, ret, body)
		@name = name
		@args = args
		@ret = ret
		@body = body
		super([func_token], [name, args, ret, body])
	end
end
class ClosureNode < Node
	attr_reader :args, :ret, :body
	def initialize(args, ret, body)
		@args = args
		@ret = ret
		@body = body

		children = []
		children.push(args)
		if ret
			children.push(ret)
		end
		children.push(body)
		super([], children)
	end
end
class ReturnNode < Node
	def initialize(return_token, exp)
		super([return_token], [exp])
	end
end
class BlockNode < Node
	def initialize(statements)
		super([], statements)
	end
end

