class Type
	def is_subst_left_type
		false
	end
end

class ScalarType < Type
	attr_reader :name
	def initialize(name)
		@name = name
	end
	def to_s
		"ScalarType(#{name})"
	end
	def ==(other)
		if other && other.is_a?(ScalarType)
			name == other.name
		else
			false
		end
	end
end

class PolyType < Type
	attr_reader :id
	def initialize(id)
		@id = id
	end
	def to_s
		"PolyType(#{id})"
	end
	def ==(other)
		if other && other.is_a?(PolyType)
			id == other.id
		else
			false
		end
	end
end

class VariableType < Type
	attr_reader :node
	def initialize(name_node)
		@node = name_node
	end
	def to_s
		"VariableType(#{node.str})"
	end
	def ==(other)
		if other && other.is_a?(VariableType)
			node == other.node
		else
			false
		end
	end
	def is_subst_left_type
		true
	end
end

class ExpressionType < Type
	attr_reader :node
	def initialize(expression_node)
		@node = expression_node
	end
	def to_s
		"ExpressionType(#{node})"
	end
	def ==(other)
		if other && other.is_a?(ExpressionType)
			node == other.node
		else
			false
		end
	end
	def is_subst_left_type
		true
	end
end

class FunctionType < Type
	attr_reader :args, :ret
	def initialize(args, ret)
		@args = args
		@ret = ret
	end
	def to_s
		"(" + args.map{|a| a.to_s }.join(", ") + ")-> #{ret}"
	end
end
