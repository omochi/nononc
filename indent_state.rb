class IndentState
	attr_reader :base_level, :is_hanging
	attr_reader :level
	def initialize(base_level, is_hanging)
		@base_level = base_level
		@is_hanging = is_hanging
		if is_hanging
			@level = base_level + 1
		else
			@level = base_level
		end
	end
	def set_hanging(value)
		return IndentState.new(@base_level, value)
	end
	def nest()
		return IndentState.new(@level, false)
	end
end