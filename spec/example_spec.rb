require "spec_helper"

require "./parser"

describe "example" do
	# TODO
	it "1" do
		r = Parser.new(
			"func hoge(a: Int)-> Void\n" +
			"  a\n" +
			"\n" +
			"func fuga(b: Float)-> Float\n" +
			"  b"
			)
		node, ws, err = r.parse_block_statement_we()		
	end
	it "2" do
		# TODO
		r = Parser.new(
			"(a)->\n" + 
			"  return a\n" +
			"(1)"
			)
		node, ws, err = r.parse_block_statement_we()
	end	
end