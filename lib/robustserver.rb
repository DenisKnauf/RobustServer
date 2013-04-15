
def Signal.signame s
	case s      
	when String then s
	when Symbol then s.to_s
	when Fixnum then list.invert[s]
	else raise ArgumentError, "String, Symbol or Fixnum expected, not #{s.class}"
	end                            
end                                    

def Signal.sig s
	case s  
	when Fixnum then s
	when String then list[s]
	when Symbol then list[s.to_s]
	else raise ArgumentError, "String, Symbol or Fixnum expected, not #{s.class}"
	end                          
end                                  

Signal.list do |n, s|
	Signal.const_set n, s
	Signal.const_set "SIG#{n}", s
end                                  

def Signal.[] s
	case s 
	when String then list[s]
	when Symbol then list[s.to_s]
	when Fixnum then list.invert[s]
	else raise ArgumentError, "String, Symbol or Fixnum expected, not #{s.class}"
	end                            
end                                    

# Description
# ===========
# 
# Counts retries ot something.  If the retries are to often in a short time,
# you shouldn't retry again.
#
# Examples
# ========
# 
# Strings aren't Integers and 2*"Text" will raise TypeError.
#
# 	retries = Retry.new 5, 1
# 	begin
# 		array_of_ints_and_some_strings.each do |i|
# 			puts 2*i
# 		end
# 	rescue TypeError
# 		retries.retry? and retry
# 		raise $!
# 	end
#
# 	Retry.new( 10, 30).run( ConnectionLost) do
# 		try_to_connect_to_db
# 		try_query
# 	end
class Retries
	attr_accessor :max, :range
	attr_reader :count, :last

	# max: How many retries in range-time are allowed maximal.
	# range: In which time-range are these retries are allowed
	def initialize max = nil, range = nil
		@max, @range, @count, @last = max || 10, range || 10, 0, Time.now
	end

	# Counts retries on every call.
	# If these retries are to often - max times in range - it will return false
	# else true.
	# Now you can say: "I give up, to many retries, it seems it doesn't work."
	def retry?
		@count = @last + @range > Time.now ? @count + 1 : 1
		@last = Time.now
		@count < @max
	end

	# Automatical retrieing on raised exceptions in block.
	# ex: Your expected Esception you will rescue. Default: Object, so realy everything.
	#
	# Example:
	# Retries.new( 10, 30).run ArgumentError do something_do_which_could_raise_exception ArgumentError end
	#
	# This will retry maximal 10 times in 30 seconds to Call this block. But only rescues ArgumentError!
	# Every other Error it will ignore and throws Exception. No retry.
	def run ex = nil, &e
		ex ||= Object
		begin e.call *args
		rescue ex
			retries.retry? and retry
		end
	end
end

# Easy problem-handler for your Server.
# 
# A Server should never crash.
# If an Exception raised, which is not rescued,  your program will shutdown abnormaly.
# Or if a signal tries to "kill" your program,  your program will shutdown abnormaly too.
# 
# With RobustServer these errors will be a more unimportant problem and  It'll be easier to handle.
# 
# Subclasses should implements *#run*,  which will be your main-worker.
# For initializing,  you can override **#initialize**,  but doen't forget to call **super**.
class RobustServer
	class UnimplementedRun <Exception
	end
	attr_reader :signals, :output

	def self.main *argv
		self.new( *argv).main
	end

	def initialize *_
		sh = method :signal_handler
		@sigs = {
			Signal[:INT] => sh, Signal[:HUP] => nil, Signal[:TERM] => sh,
			Signal[:KILL] => sh, Signal[:USR1] => nil, Signal[:USR2] => nil
		}
		@signals, @output = [], $stderr
	end

	def trapping
		@sigs.each { |s, p|  @sigs[s] = trap s, p  }  if @sigs
	end

	def signal_handler s
		output.puts [:signal, s, Signal[s]].inspect
		s = s
		@signals.push s  unless @signals.include? s
	end

	def main max = nil, range = nil
		retries = Retries.new max, range
		trapping
		output.puts "Running...."
		begin
			self.run
		rescue UnimplementedRun
			raise
		rescue SystemExit
			output.puts "Server interrupted by signal: #$!"
			raise
		rescue Interrupt, SignalException
			output.puts "Server interrupted by signal: #$!"
			exit 0
		rescue Object
			output.puts [:rescue, $!, $!.class, $!.backtrace].inspect
			retry  if retries.retry?
			output.print "Too many errors in too short time. Give up: "
		end
	ensure
		output.puts "Disregarded signals: #{@signals.map(&Signal.method(:[])).join( ', ')}"
		trapping
		self.at_exit
		output.puts "Shutdown."
	end

	def run
		raise UnimplementedRun, "Unimplemented #{self.class.name}#run."
	end

	def at_exit
	end
end
