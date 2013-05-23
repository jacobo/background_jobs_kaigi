# (rvm use 1.9.3)
#In one terminal run: unicorn unicornhax.ru
#In another run: curl -v localhost:8080

require 'rubygems'
require 'redis'
REDIS = Redis.connect

require 'unicorn'
Unicorn::Worker.class_eval do
  alias :old_tick= :tick=
  def tick=(val)
    if(job = REDIS.lpop("jobs_q"))
      sleep 2
      x = job.to_i
      50.times{print [128000+x].pack "U*"}
    end
    self.old_tick = val
  end
end

seq = 0
run lambda{ |env|
  REDIS.rpush("jobs_q", seq)
  seq += 1
  [200, {"Content-Type" => "text/html"}, ["Hello World\n"]]
}

