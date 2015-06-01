require "./node"
require "./type"

class TypeConstraint
	attr_reader :lhs
	attr_reader :rhs
	def initialize(lhs, rhs)
		@lhs = lhs
		@rhs = rhs
	end
	def to_s
		"#{lhs.to_s} = #{rhs.to_s}"
	end
end

class TypeSubstitution
	attr_reader :lhs
	attr_reader :rhs
	def initialize(lhs, rhs)
		if not lhs.is_subst_left_type
			raise "invalid lhs: #{lhs}"
		end
		@lhs = lhs
		@rhs = rhs
	end
	def to_s
		"#{lhs.to_s} => #{rhs.to_s}"
	end
	def apply(type)
		type_substitution_apply(self, type)
	end
end

class TypeSubstitutionTable
	attr_reader :entries
	def initialize(entries = [])
		@entries = entries
	end
	def to_s
		entries.join("\n")
	end
	def apply(type)
		entries.reduce(type) do |type, entry|
			entry.apply(type)
		end
	end
	def +(table)
		TypeSubstitutionTable.new(
			entries + table.entries)
	end
	def find(type)
		for subst in entries
			if subst.lhs == type
				return subst
			end 
		end
		return nil
	end
	def push(new_subst)
		# TODO occur check
		new_subst = TypeSubstitution.new(
			new_subst.lhs, apply(new_subst.rhs))
		new_entries = entries.map do |entry|
			TypeSubstitution.new(
				entry.lhs,
				new_subst.apply(entry.rhs))
		end
		new_entries.push(new_subst)
		return TypeSubstitutionTable.new(new_entries)
	end
end

$next_poly_type_id = 0

def generate_new_poly_type()
	id = $next_poly_type_id
	$next_poly_type_id += 1
	return PolyType.new(id)
end

def collect_type_constraints(env, node)
	if node.is_a?(NameNode)
		if not name_value = env[node.str]
			raise "undefined variable: #{node}"
		end
		const = TypeConstraint.new(
			ExpressionType.new(node),
			VariableType.new(name_value))
		return [const]
	elsif node.is_a?(ClosureNode)
		consts = []

		new_env = node.generate_local_env(env)

		arg_var_types = []
		for arg in node.args
			if not name_value = new_env[arg.name.str]
				raise "never: #{arg.name.str} not in #{new_env}"
			end
			arg_var_type = VariableType.new(name_value)
			arg_var_types.push(arg_var_type)

			consts.push(TypeConstraint.new(
				arg_var_type, generate_new_poly_type()
				))
		end

		for statement in node.body
			consts += collect_type_constraints(new_env, statement)

			if statement.is_a?(ReturnNode)
				ret_exp_type = ExpressionType.new(statement)

				const = TypeConstraint.new(
					ExpressionType.new(node),
					FunctionType.new(arg_var_types, ret_exp_type))
				consts.push(const)
			end
		end

		if not ret_exp_type
			raise "TODO: no return closure"
		end

		return consts
	elsif node.is_a?(ReturnNode)
		consts = []
		if exp = node.expression
			consts += collect_type_constraints(env, exp)
			const = TypeConstraint.new(
				ExpressionType.new(node),
				ExpressionType.new(exp))
			consts.push(const)
		else
			const = TypeConstraint.new(
				ExpressionType.new(node),
				ScalarType.new("Void"))
			consts.push(const)
		end
		return consts
	else
		raise "TODO: #{node}"
	end
end

def type_substitution_apply(subst, type)
	if type.is_subst_left_type()
		if type == subst.lhs
			return subst.rhs
		end
		return type
	elsif type.is_a?(FunctionType)
		return FunctionType.new(
			type.args.map {|t| subst.apply(t) },
			subst.apply(type.ret))
	else
		return type
	end
end

def unify_type_step(consts, subst_table)
	consts = consts.clone()
	if not const = consts.delete_at(0)
		return subst_table
	end
	lhs = const.lhs
	rhs = const.rhs

	if lhs.is_subst_left_type
		if subst = subst_table.find(lhs)
			consts.push(
				TypeConstraint.new(rhs, subst.rhs))
			return unify_type_step(consts, subst_table)
		else
			subst_table = subst_table.push(
				TypeSubstitution.new(lhs, rhs))
			return unify_type_step(consts, subst_table)
		end
	elsif rhs.is_subst_left_type
		consts.push(
			TypeConstraint.new(rhs, lhs))
		return unify_type_step(consts, subst_table)
	elsif lhs.is_a?(ScalarType)
		if lhs == rhs
			return unify_type_step(consts, subst_table)
		end
	elsif lhs.is_a?(FunctionType)
		if rhs.is_a?(FunctionType)
			if lhs.args.length != rhs.args.length
				raise "args nums not equal: lhs=#{lhs}, rhs=#{rhs}"
			end
			i = 0
			while i < lhs.args.length
				consts.push(
					TypeConstraint.new(lhs.args[i], rhs.args[i]))
				i += 1
			end
			consts.push(
				TypeConstraint.new(lhs.ret, rhs.ret))
			return unify_type_step(consts, subst_table)
		end
	else
		raise "TODO: #{lhs}"
	end
	raise "invalid type pair: lhs=#{lhs}, rhs=#{rhs}"
end

def unify_type(constraints)
	return unify_type_step(constraints, TypeSubstitutionTable.new())
end