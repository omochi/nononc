require "spec_helper"

require "./type/type_constrain"

describe "type_infer" do
	# it "1" do
	# 	parser = Parser.new("1")
	# 	token, ws = parser.read_code_token_w()
	# 	node, ws, err = parser.parse_element_we(token)
	# 	expect(node).to be_a IntLiteralNode

	# 	cs = get_type_constrains(node)
	# 	p cs
	# end
	# it "2" do
	# 	parser = Parser.new(
	# 		"((a)->\n" +
	# 		"  return a)(3)"
	# 		)
	# 	node, ws, err = parser.parse_block_statement_we()
	# 	expect(node[0]).to be_a CallNode
	# 	cs = get_type_constrains(node[0])
	# 	p cs
	# end
end