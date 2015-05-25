#!/usr/bin/env ruby

require "./char"
require "./token"
require "./node"
require "./parser"

def main()
	file = File.open(ARGV[0])
	source = file.read()
	file.close()

	parser = Parser.new(source)
	file, err = parser.parse_file_e()
	if err
		p err
		return
	end
	if file
		puts file.inspect
	end

	puts "token reconstruct"
	parser.tokens.each { |t| print t.str }
end
main()
