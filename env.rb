class Env
	attr_accessor :name_table
	attr_accessor :parent
	def initialize()
		@name_table = {}
		@parent = nil
	end
	def copy()
		env = Env.new()
		env.name_table = name_table
		env.parent = parent
		env
	end
	def with_name_table(value)
		env = copy()
		env.name_table = value
		env
	end
	def make_child()
		env = Env.new()
		env.parent = self
		env
	end
	def [](name)
		if value = @name_table[name]
			return value
		end
		if parent
			return parent[name]
		else
			return nil
		end
	end
	def to_s
		parts = []
		parts += @name_table.keys
		parts_str = parts.join(",")
		return "#{self.class}(" + parts_str + ")"
	end
end

class EnvNodePrinter
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

class EnvNode
	attr_reader :env
	attr_reader :node
	def initialize(env, node)
		@env = env
		@node = node
	end
end




class NameEnvNode < EnvNode
end
class TypeEnvNode < EnvNode
end
class VariableDeclarationEnvNode < EnvNode
	attr_reader :name
	attr_reader :type
	def initialize(
		env, node,
		name, type)
		@name = name
		@type = type
		super(env, node)
	end
	def children
		cr = [name]
		if type
			cr.push(type)
		end
		cr
	end
end

class ClosureEnvNode < EnvNode
	attr_reader :args, :ret, :body
	def initialize(env, node, args, ret, body)
		@args = args
		@ret = ret
		@body = body
		super(env, node)
	end
	def children
		cr = args
		if ret 
			cr.push(ret)
		end
		cr += body
		return cr
	end
end
class ReturnEnvNode < EnvNode
	attr_reader :expression
	def initialize(env, node, expression)
		@expression = expression
		super(env, node)
	end
	def children
		[expression]
	end
end

class VarInstance
	attr_reader :name
	def initialize(name)
		@name = name
	end
end

def build_env_node(env, node)
	if node == nil
		return nil
	elsif node.is_a?(NameNode)
		return node.with_children().set_env(env)
	elsif node.is_a?(TypeNode)
		return node.with_children().set_env(env)
	elsif node.is_a?(VariableDeclarationNode)
		return node.with_children(
			build_env_node(env, node.name),
			build_env_node(env, node.type)
			).set_env(env)
	elsif node.is_a?(ReturnNode)
		return node.with_children(
			build_env_node(env, node.expression)
			).set_env(env)
	elsif node.is_a?(ClosureNode)
		name_table = {}
		for arg in node.args
			name_table[arg.name.str] = VarInstance.new(arg.name)
		end
		new_env = env.make_child(name_table)

		new_args = node.args.map do |arg|
			build_env_node(new_env, arg)
		end
		new_ret = build_env_node(new_env, node.ret)
		new_body = node.body.map do |statement|
			build_env_node(new_env, statement)
		end

		return node.with_children(new_args, new_ret, new_body)
			.set_env(new_env)
	else
		raise "TODO: #{node}"
	end
end