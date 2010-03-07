
def Signal.signame s
	case s      
	when String then s
	when Symbol then s.to_s
	when Fixnum then list.invert[s]
	end                            
end                                    

def Signal.sig s
	case s  
	when Fixnum then s
	when String then list[s]
	when Symbol then list[s.to_s]
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
	else raise ArgumentError       
	end                            
end                                    

class Retries
	attr_accessor :max, :range
	attr_reader :count, :last

	def initialize max = nil, range = nil
		@max, @range, @count, @last = max || 10, range || 10, 0, Time.now
	end

	def retry?
		@count = @last + @range > Time.now ? @count + 1 : 1
		@last = Time.now
		@count < @max
	end

	def run ex, &e
		begin e.call *args
		rescue ex
			retries.retry? and retry
		end
	end
end

class RobustServer
	attr_reader :signals

	def self.main *argv
		self.new( *argv).main
	end

	def initialize *p
		sh = method :signal_handler
		@sigs = {
			Signal[:INT] => sh, Signal[:HUP] => nil, Signal[:TERM] => sh,
			Signal[:KILL] => sh, Signal[:USR1] => nil, Signal[:USR2] => nil
		}
		@signals = []
	end

	def trapping
		@sigs.each { |s, p|  @sigs[s] = trap s, p  }  if @sigs
	end

	def signal_handler s
		$stderr.puts [:signal, s, Signal[s]].inspect
		s = s
		@signals.push s  unless @signals.include? s
	end

	def main max = nil, range = nil
		retries = Retries.new max, range
		trapping
		$stderr.puts "Arbeit wird nun aufgenommen..."
		begin
			self.run
		rescue SystemExit, Interrupt, SignalException
			$stderr.puts "Das Beenden des Programms wurde angefordert. #{$!}"
		rescue Object
			$stderr.puts [:rescue, $!, $!.class, $!.backtrace].inspect
			retry  if retries.retry?
			$stderr.print "Zuviele Fehler in zu kurzer Zeit.  Ich gebe auf und "
		end
		$stderr.puts "Unbeachtete Signale: #{@signals.map(&Signal.method(:[])).join( ', ')}"
		trapping
		$stderr.puts "Beende mich selbst."
	end
end
