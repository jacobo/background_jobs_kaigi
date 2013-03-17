require 'celluloid'

class DiCaprio
  include Celluloid

  def do_a_thing
    puts "starting"
    `sleep 1`
    puts "finished"
  end

end

class Deniro
  include Celluloid

  def do_something
    puts "starting"
    sleep 1
    puts "finished"
  end

end

leo = DiCaprio.new
5.times{ leo.async.do_a_thing }

robert = Deniro.new
5.times{ robert.async.do_something }

Thread.stop

#the answer is in:
#https://github.com/celluloid/celluloid/wiki/Pipelining-and-execution-modes
# https://github.com/celluloid/celluloid/wiki/Exclusive

class Exclusive
  include Celluloid

  def do_things
    exclusive do
      puts "starting"
      sleep 1
      puts "finished"
    end
  end

end
