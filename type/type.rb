class Type
end

class VoidType < Type
end

class IntType < Type
end

class FloatType < Type
end

class VarType < Type
	attr_reader :node
	def initialize(node)
		@node = node
	end
end

class FunctionType < Type
	attr_reader :arg_types, :ret_type
	def initialize(arg_types, ret_type)
		arg_types.each_with_index do |arg_type, index| 
			if not arg_type.is_a?(Type)
				raise "arg_type[#{index}] is not a type: #{arg_type}"
			end
		end
		if not ret_type.is_a?(Type)
			raise "ret_type is not at type: #{ret_type}"
		end

		@arg_types = arg_types
		@ret_type = ret_type
	end
end

class NodeType < Type
	attr_reader :node
	def initialize(node)
		@node = node
	end
end

