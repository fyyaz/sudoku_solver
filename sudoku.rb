# A Sudoku solver written in Ruby

module Sudoku

	#Puzzle class used to represent the 9x9 grid in sudoku

	class Puzzle

		## constants used to translate between ascii and binary 
		ASCII = ".123456789" #external representation
		BIN = "\000\001\002\003\004\005\006\007\010\011" #internal represenatation

		def initialize(lines)
			if (lines.respond_to? :join) #if argument looks like an array
				s = lines.join #joins the lines into a string
			else
				s = lines.dup #assuming lines is a string create a private copy
			end
		
			#Need to remove whitespace from the input data
			s.gsub!(/\s/, "") #replace any whitespace (\s regex) with an empty string

			#check if wrong size and raise an exception
			raise Invalid, "Grid is the wrong sizr" unless s.size == 81

			if i = s.index(/[^123456789\.]/)
				#i is not nil if there is a character other than the ones above
				raise Invalid, "Illegal character #{s[i,1]} in the puzzle"
			end

			#convert the string from ascii characters to the internal representation
			s.tr!(ASCII, BIN) #translate the string from ascii to the internal

			@grid = s.unpack('c*') #unpack bytes into an array of numbers

			#dont allow duplicates in the puzzle
			raise Invalid, "Initial puzzle has duplicates" if has_duplicates?
		end

		#Return the puzzle as a string of 9 lines with 9 chars each
		def to_s
			#reverse the initialize method 
			#invokes pack 9 times and puts it in a array, join joins all the elements
			#into a string with newline delimitiers and then tr translates back from
			#BIN to ASCII
			(0..8).collect{|r| @grid[r*9,9].pack('c9')}.join("\n").tr(BIN, ASCII)
		end

		#returns a duplicate of the puzzle
		def dup 
			copy = super #make shallow copy from Object.dup
			@grid = @grid.dup #makes a new copy of the data
			copy #returns the copied object
		end

		#override the [] operator for the puzzle
		def [] (row, col)
			#converts from row, col coordinates to a single coordinate and returns 
			#that cell
			@grid[roe*9 + col]
		end

		# this method allows you to change puzzle values
		def []= (row, col, newvalue)
			unless (0..9).include? newvalue 
				#raise an exception if the number is not valid for sudoku
				raise Invalid, "Illegal cell value" 
			end

			@grid[row *9 + col] = newvalue
		end

		# constant array to map from one dimensoinal grid number to box number
		# frozen = cant change
		BoxOfIndex = [
			0,0,0,1,1,1,2,2,2,0,0,0,1,1,1,2,2,2,0,0,0,1,1,1,2,2,2,
			3,3,3,4,4,4,5,5,5,3,3,3,4,4,4,5,5,5,3,3,3,4,4,4,5,5,5,
			6,6,6,7,7,7,8,8,8,6,6,6,7,7,7,8,8,8,6,6,6,7,7,7,8,8,8
		].freeze

		#defines a custom iterator for the puzzle class to go through the 
		#puzzle and return any cells that we dont know the value of
		def each_unknown
			0.upto 8 do |row|
				0.upto 8 do |col|
					index = row*9 + col 
					next if @grid[index]!=0 #continue if cell value known
					box = BoxOfIndex[index]
					yield row, col, box #yield passes item back to the block that called it
				end
			end
		end

		def has_duplicates?
			0.upto(8) {|row| return true if rowdigits(row).uniq!}
			0.upto(8) {|col| return true if coldigits(col).uniq!}
			0.upto(8) {|box| return true if bixdigits(box).uniq!}
			
			#no duplicates, all tests passed
			false

		end

		#All valid Sudoku digits
		AllDigits = [1,2,3,4,5,6,7,8,9].freeze

		#returns nil if not possible otherwise returns some other value
		def possible(row, col, box)
			AllDigits - (rowdigits(row) + coldigits(col) + boxdigits(box))
		end

		private

		def rowdigits(row)
			@grid[row*9, 9] - [0]
		end

		def coldigits(col)
			res = []

			#loop from col in steps of 9 upto 80
			col.step(80, 9) { |i|
				v = @grid[i]
				res << v if v!=0
			}

			res
		end

		 BoxToIndex = [0, 3, 6, 27, 30, 33, 54, 57, 60].freeze

		 def boxdigits(box)
		 	i = BoxToIndex[box]
		 	
		 	#return the box with 0 removed
		 	[
		 		@grid[i], @grid[i+1], @grid[i+2],
				@grid[i+9], @grid[i+10], @grid[i+11],
				@grid[i+18], @grid[i+19], @grid[i+20]
		 	] - [0]
		 end

	end #end puzzle

	# class used for invalid input
	class Invalid < StandardError
	end

	#class used for invalid puzzle (no solution)
	class Impossible < StandardError
	end

	def Sudoku.scan(puzzle)
		
		#Loop variable
		unchanged = false

		until unchanged
			unchanged = true #no cells changed yet

			rmin, cmin,pmin = nil 
			min = 10

			puzzle.each_unknown do |row, col, box|
				p = puzzle.possible(row, col, box)

				case p.size
				when 0 #no possible solutions
					raise Impossible, "No solutions"
				when 1 # unique value => set the grid
					puzzle[row, col] = p[0]
					unchanged = false
				else #any other number of posibilities (like default)
					if unchanged && p.size < min
						min = p.size #current smallest size
						rmin, cmin, pmin = row, col, p #parallel assignment
					end
				end
			end
		end

		#return the minimum set of possibilities
		return rmin, cmin, pmin
	end

	#method to solve a puzzle
	def Sudoku.solve(puzzle)
		#create a private copy of the puzzle
		puzzle = puzzle.dup

		#get row, column and possibilities at a cell
		r,c,p = scan(puzzle)

		return puzzle if r == nil

		p.each do |guess|

			puzzle[r,c] = guess #try the guessed value

			begin
				#solve by recursively calling scan
				return solve(puzzle)

			rescue Impossible #catch impossible exception and try next guess
				next
			end
		end

		#No solutions for puzzle since solve did not return 
		raise Impossible
	end
end
















