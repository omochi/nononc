require "spec_helper"

require "./infer"

describe "type_infer" do
	it "temp1", focus: true do
		parser = Parser.new(
			"(a)->\n" +
			"  return a"
			)
		node, ws, err = parser.parse_block_statement_we()
		expect(node[0]).to be_a ClosureNode

		consts = collect_type_constraints(Env.new(), node[0])
		puts "consts"
		puts consts.join("\n")

		subst_table = unify_type(consts)
		puts "subst table"
		puts subst_table
	end
end