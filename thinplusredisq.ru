#In one terminal run: thin start --rackup thinplusresque.ru
#In another run: curl -v localhost:3000

require 'thin'
require 'resque'
require 'sinatra/base'

class Job
  @queue = "jobs"
  def self.perform(arg)
    sleep 0.1
    x = arg.to_i
    puts x*x
  end
end

class Worker
  def self.started?; @started; end
  def self.start
    worker = Resque::Worker.new("*")
    EventMachine.add_periodic_timer( 0.1 ) do
      if job = worker.reserve
        worker.perform(job)
      end
    end
    @started = true
  end
end

class Server < Sinatra::Base
  @@counter = 0
  get "/" do
    Worker.start unless Worker.started?
    Resque.enqueue Job, @@counter += 1
    "hello world\n"
  end
end

run Server