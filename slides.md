!SLIDE[bg=images/beanstalksurf.jpg]
### Jacob Burkhart
<br/><br/><br/><br/>
<br/><br/><br/><br/>
<br/><br/><br/><br/><br/>
## [@beanstalksurf](http://twitter.com/beanstalksurf)

!SLIDE
### How to Fail at Background Jobs
## `jacobo.github.com/background_jobs_kaigi`

!SLIDE
#Engine Yard
(we run servers)

!SLIDE
#The Story of a Bug

!SLIDE
### Starling, Workling

    @@@ ruby
    class ServerBootJob < Workling::Base
      def boot_server(server_id)
        ...
      end
    end
    ServerBootJob.async_boot_server(server.id)

    Workling::Remote.dispatcher =
      Workling::Remote::Runners::StarlingRunner.new

&nbsp;

    @@@ ruby
    starling -f config/starling.yml
    script/workling_client run

!SLIDE
### RabbitMQ, AMQP

    @@@ ruby
    connection = AMQP.connect(:host => '127.0.0.1')

    channel  = AMQP::Channel.new(connection)
    queue    = channel.queue("serverbooter")
    exchange = channel.default_exchange

    queue.subscribe do |payload|
      puts "Boot server: #{payload}"
    end

    exchange.publish JSON.encode(:server_id => 10),
                     :routing_key => "serverbooter"

## `github.com/ruby-amqp/amqp`
## `github.com/ruby-amqp/bunny`


!SLIDE
### ActiveRecord:: RecordNotFound

    @@@ ruby
    class Server < ActiveRecord::Base
      after_create do |s|
        ServerBootJob.async_run(s.id)
      end
    end

    class ServerBootJob < BackgroundJob
      def run(server_id)
        #sleep 1 ?
        server = Server.find(server_id)
        ...
      end
    end

!SLIDE
(diagram)

!SLIDE
### Hack ActiveRecord

    @@@ ruby
    class Server < ActiveRecord::Base
      after_create do |s|
        s.commit_callback do
          ServerBooter.async_run(s.id)
        end
      end
    end

    ...
    def commit_callback
      self.connection.instance_eval do
        class << self
          alias commit_db_transaction_original commit_db_transaction
          ...

## `github.com/brontes3d/commit_callback`
(rails 2.3 only)

!SLIDE
### A Service Object

    @@@ ruby
    class ServerBooter
      def self.create_and_boot_server!(...)
        server = Server.create!(...)
        ServerBootJob.async_run(server.id)
        server
      end
    end

    class ServerBootJob < BackgroundJob
      def run(server_id)
        server = Server.find(server_id)
        ...
      end
    end

!SLIDE
### after_commit


    @@@ ruby
    class Server < ActiveRecord::Base
      after_commit do |s|
        ServerBooter.async_run(s.id)
      end
    end

## See Also: `http://bitly.com/IqdwGP`
## See Also: `http://bitly.com/OLij33`

!SLIDE align-left
### after_commit

## "If any exceptions are raised within one of these callbacks, they will be ignored so that they don’t interfere with the other callbacks" -- Rails Guide

## `http://bitly.com/hlUiBc`

!SLIDE
#3 Parts

Loop

Queue

Runner

!SLIDE
#The simplest thing that can possibly work

!SLIDE
###Threads

    @@@ ruby
    work = (0..99).to_a
    worker = lambda{|x| sleep 0.1; puts x*x }

    workers = work.map do |x|
      Thread.new do
        worker.call(x)
      end
    end
    workers.map(&:join)

!SLIDE
###Thread Pool

    @@@ ruby
    require 'thread'
    work_q = Queue.new
    (0..99).to_a.each{|x| work_q.push x }
    workers = (0...10).map do
      Thread.new do
        begin
          while x = work_q.pop(true)
            sleep 0.1; puts x*x
          end
        rescue ThreadError
        end
      end
    end
    workers.map(&:join)

!SLIDE
###DRB

    @@@ ruby
    require 'drb'
    server_pid = fork do
      DRb.start_service "druby://localhost:28371", (0..99).to_a
      DRb.thread.join
    end
    work_q = DRbObject.new nil, "druby://localhost:28371"
    worker_pids = (0...10).map do |i|
      fork do
        #sleep(i) #else DRb::DRbConnError in ruby < 2.0
        while x = work_q.pop
          sleep 0.1; puts x*x
        end
      end
    end
    worker_pids.each{ |pid| Process.wait(pid) }
    Process.kill("KILL", server_pid)

!SLIDE

# `github.com/engineyard/ multi_headed_greek_monster`

    @@@ruby
    require 'multi_headed_greek_monster'

    monster = MultiHeadedGreekMonster.new(nil, 10) do |x, work|
      sleep 0.1; puts x*x
    end
    (0..100).to_a.each do |x|
      monster.feed(x)
    end
    monster.finish


!SLIDE
#DIY

!SLIDE
    @@@ruby
    class TrapLoop
      trap('TERM') { stop! }
      trap('INT')  { stop! }
      trap('SIGTERM') { stop! }

      def self.stop!
        @loop = false
      end
      def self.safe_exit_point!
        if @started && !@loop
          raise Interrupt
        end
      end
      def self.start(&block)
        @started = true
        @loop = true
        while(@loop) do
          yield
          safe_exit_point!
        end
      end
    end

!SLIDE
    @@@ruby
    REDIS = Redis.connect(:url => "redis://#{redishost}")

    class ServerBootJob
      def self.enq_job(server_id)
        REDIS.rpush("server_boot_jobs", server_id)
      end

      def self.process_jobs!
        while(server_id = REDIS.lpop("server_boot_jobs"))
          if server = Server.find_by_id(server_id)
            server.boot!
            TrapLoop.safe_exit_point!
          end
        end
      end
    end

!SLIDE

## `script/server_boot_worker`

    @@@ ruby
    #!/usr/bin/env ruby
    require File.expand_path('../../config/environment',
      __FILE__)

    TrapLoop.start do
      ServerBootJob.process_jobs!
    end

## `script/server_boot_runner start`
## `script/server_boot_runner stop`

    @@@ ruby
    require 'daemons'
    Daemons.run(File.expand_path('../server_boot_worker',
      __FILE__),
      log_output: true, backtrace: true,
      dir_mode: :normal, multiple: true, :monitor: true,
      dir: File.expand_path('../../tmp/pids',  __FILE__),
      log_dir: File.expand_path('../../log',  __FILE__))


!SLIDE
#Failing at Loops

talk to AMQP and XMPP from the same system
talk to AMQP or XMPP from a web server

!SLIDE
#Failing at Queues

try to debug what's going on and bring down your production system

!SLIDE
#Failing at Runners
graceful restart
fail to restart and see zombie workers swallow your jobs

!SLIDE
#Failing at Background Jobs

jobs that depend on other jobs
jobs that need to run on a schedule
multi-Q systems
