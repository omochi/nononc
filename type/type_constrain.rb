require "./node"
require "./type/type"

class TypeConstrain
	attr_reader :lhs, :rhs
	def initialize(lhs, rhs)
		if not lhs.is_a?(Type)
			raise "lhs is not a type: #{lhs}"
		end
		if not rhs.is_a?(Type)
			raise "rhs is not a type: #{rhs}"
		end
		@lhs = lhs
		@rhs = rhs
	end
end

def get_type_constrains(node)
	if node.is_a?(IntLiteralNode)
		[ TypeConstrain.new(NodeType.new(node), IntType.new()) ]
	elsif node.is_a?(NameNode)
		[ TypeConstrain.new(NodeType.new(node), VarType.new(node)) ]
	elsif node.is_a?(ParenExpressionNode)
		get_paren_expression_type_constrains(node)
	elsif node.is_a?(ClosureNode)
		get_closure_type_constrains(node)
	elsif node.is_a?(CallNode)
		get_call_type_constrains(node)
	else
		puts "no constrains for: #{node}"
		[]
	end
end

def get_paren_expression_type_constrains(node)
	if node.children.length == 0
		[ TypeConstrain.new(NodeType.new(node), VoidType.new()) ]
	elsif node.children.length == 1
		cs = [ TypeConstrain.new(NodeType.new(node), NodeType.new(node[0])) ]
		cs += get_type_constrains(node[0])
		cs
	else
		raise "TODO: tuple type"
	end
end

def get_closure_type_constrains(node)
	cs = []

	arg_types = []

	arg_paren_node = node.args
	if not arg_paren_node.is_a?(ParenVariableDeclarationNode)
		raise "arg_paren_node is not a ParenVariableDeclarationNode: #{arg_paren_node}"
	end
	for arg_node in arg_paren_node.children
		if not arg_node.is_a?(VariableDeclarationNode)
			raise "arg_node is not a VariableDeclarationNode: #{arg_node}"
		end
		arg_name_node = arg_node.children[0]
		if not arg_name_node.is_a?(NameNode)
			raise "arg_name_node is not a NameNode: #{arg_name_node}"
		end
		arg_types.push(VarType.new(arg_name_node))
	end

	for body_entry in node.body.children
		if body_entry.is_a?(ReturnNode)
			return_node = body_entry

			if ret_exp_node = return_node.children.first
				cs += get_type_constrains(ret_exp_node)
				ret_type = NodeType.new(ret_exp_node)
			else
				ret_type = VoidType.new()
			end

			c = TypeConstrain.new(NodeType.new(node),
					FunctionType.new(arg_types, ret_type))
			cs.push(c)
		else
			cs += get_type_constrains(body_entry)
		end
	end

	return cs
end

def get_call_type_constrains(node)
	cs = []

	callee_node = node[0]
	arg_nodes = node.children[1, node.children.length - 1]

	arg_types = []

	cs += get_type_constrains(callee_node)
	for arg_node in arg_nodes
		cs += get_type_constrains(arg_node)
		arg_types.push(NodeType.new(arg_node))
	end

	c = TypeConstrain.new(NodeType.new(callee_node),
			FunctionType.new(arg_types, NodeType.new(node)))

	cs.push(c)

	return cs
end