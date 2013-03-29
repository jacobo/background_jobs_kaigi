!SLIDE[bg=images/beanstalksurf.jpg]
### Jacob Burkhart
<br/><br/><br/><br/>
<br/><br/><br/><br/>
<br/><br/><br/><br/><br/>
## @beanstalksurf

!SLIDE[bg=images/distill.jpg]
### Engine Yard

!SLIDE[bg=images/closeout.jpg] black
### How to Fail at Background Jobs
## `jacobo.github.com/background_jobs`

.notes Failure is a good thing. I want to spark conversations.

!SLIDE
### DRB is built-in

## Queue Server
    @@@ ruby
    require 'drb'
    DRb.start_service "druby://localhost:23121", []
    DRb.thread.join

## Push into the Q

    @@@ ruby
    remote_q = DRbObject.new nil, "druby://localhost:23121"
    remote_q.push("some work")

## Work it off
    @@@ ruby
    remote_q = DRbObject.new nil, "druby://localhost:23121"
    while(work = remote_q.pop)
      puts "doing #{work}"
    end

!SLIDE
### Use it for migrations

    @@@ ruby
    m = MultiHeadedGreekMonster.new(nil, 3, 28371) do |f, w|
      f.name = f.name + " improved"
      f.save!
    end
    Face.all.each do |f|
      monster.feed(f)
    end
    monster.finish

`github.com/engineyard/multi_headed_greek_monster`


!SLIDE[bg=images/skimboard.jpg]
### Rails 4 Queuing

!SLIDE
### Fail at the API

    @@@ ruby
    class MyJob

      def initialize(account)
        @account = account
      end

      def run
        puts "working on #{@account.name}..."
      end

    end

    Rails.queue[:jobs].push(MyJob.new(account))


!SLIDE[bg=images/marshal.png]
### Fail at Serialization
&nbsp;

!SLIDE
### Solve the wrong problem

    @@@ ruby
    class BodyProxy
      def each
        @body.each{|x| yield x}
        while(email = CleverMailer.emails_to_send.pop)
          email.deliver
        end
      end
    end

    def call(env)
      status, headers, body = @app.call(env)
      headers["Content-Length"] = body.map(&:bytesize).sum
      [status, headers, BodyProxy.new(body)]
    end

!SLIDE
### Will revisit in 4.1

## `github.com/rails/rails/pull/9910`
## `github.com/rails/rails/pull/9924`

!SLIDE[bg=images/skimboardfail.jpg]
### Moving on...

!SLIDE
### Teeth

    @@@ ruby
    define_system(:us_child) do

      common_name "Universal System for deciduous dentition"

      upper_right "E", "D", "C", "B", "A"

      upper_left  "J", "I", "H", "G", "F"

      lower_right "P", "Q", "R", "S", "T"

      lower_left  "K", "L", "M", "N", "O"

    end

## `github.com/brontes3d/tooth_numbering`

.notes The theme of this section is doing it yourself. The lesson is to use the Q systems as intended and follow their best practices.

!SLIDE
### 2009

![](images/3m-lava-chairside-oral-scanner.jpg)

!SLIDE
### XMPP
### a.k.a. Jabber
### a Chat protocol
## `xmpp.org/xmpp-protocols/xmpp-extensions`
## `github.com/djabberd/DJabberd`
## `github.com/brontes3d/xmpp4r`
## `github.com/brontes3d/xmpp_messaging`

!SLIDE
### Write your own clustering

    @@@ perl
      my($mailbox, $private_group) = Spread::connect(
        spread_name => '4444@host.domain.com');

      Spread::multicast($mbox, SAFE_MESS, @joined_groups,
        0, "Important Message");

`search.cpan.org/~jesus/Spread-3.17.4.4/Spread.pm`

`www.spread.org/docs/spread_docs_4/docs/message_types.html`

## `rbspread.sourceforge.net`

!SLIDE
### Starling, Workling

    @@@ ruby
    class FileCopier < Workling::Base
      def copy_case_files(options)
        ...
      end
    end
    FileCopier.async_copy_case_files(...)

    Workling::Remote.dispatcher = 
      Workling::Remote::Runners::StarlingRunner.new

&nbsp;

    @@@ ruby
    starling -f config/starling.yml
    script/workling_client run

!SLIDE[bg=images/failwhale.png]
&nbsp;

.notes Stolen from: http://www.subcide.com/experiments/fail-whale/

!SLIDE[bg=images/rabbitmq.png]
&nbsp;

.notes http://www.rabbitmq.com/
.notes "Robust" only when you setup your queues and topics and exchanges correctly, and set them to be durable, and send durable messages, and send acks.
.notes so we made sore rabbit was sending and handling messages reliably because we were told this is a feature of rabbit. not because it's something we thought we needed.  In my experience, generally you have many more problems with message execution, than you do with message delivery.

!SLIDE
### AMQP

    @@@ ruby
    connection = AMQP.connect(:host => '127.0.0.1')

    channel  = AMQP::Channel.new(connection)
    queue    = channel.queue("some.q")
    exchange = channel.default_exchange

    queue.subscribe do |payload|
      puts "Received a message: #{payload}"
    end

    exchange.publish "Hello, world!", 
                     :routing_key => queue.name

## `github.com/ruby-amqp/amqp`
## `github.com/ruby-amqp/bunny`

!SLIDE[bg=images/worklingrunners.png]
&nbsp;

.notes Brontes fork of workling at: https://github.com/brontes3d/workling

!SLIDE[bg=images/bug.jpg]
### Little Bug

!SLIDE
### ActiveRecord:: RecordNotFound

    @@@ ruby
    class Device < ActiveRecord::Base
      after_create do |d|
        # enqueue BackgroundJob with d.id
      end
    end

    class BackgroundJob
      def run(device_id)
        Device.find(device_id)
      end
    end

## `after_create` != `after_sql_commit`

!SLIDE
### Hack ActiveRecord

    @@@ ruby
    class Device < ActiveRecord::Base
      after_create do |d|
        d.commit_callback do
          # enqueue BackgroundJob with d.id
        end
      end
    end

    def commit_callback
      self.connection.instance_eval do
        class << self
          alias commit_db_transaction_original_for_commit_callback_hook commit_db_transaction
          ...


## `github.com/brontes3d/commit_callback`

!SLIDE[bg=images/manybugs.jpg]
### More Bugs

!SLIDE[bg=images/steep.jpg]
### Fundamental Flaw

.notes generic abstractions are hard
.notes poll vs. push
.notes because workling controls the run loop, we couldn't easily mix with EM-based xmpp
.notes spinning up (and down) an event machine every time you need to send a message is really crappy

!SLIDE
### Do it Yourself

    @@@ ruby
    class CaseFilesCopier < AmqpListener::Listener
      subscribes_to :case_file_copy_requests

      def handle(options)
        ...
      end
    end

    CaseFilesCopier.notify(...)

&nbsp;

    @@@ ruby
    script/amqp_listener run

## github.com/brontes3d/amqp_listener

!SLIDE
### AMQP: Failover

    @@@ ruby
    def self.determine_reconnect_server(opts)
      try_host = opts[:host]
      try_port = opts[:port]
      @retry_count ||= 0
      if opts[:max_retry] && @retry_count >= opts[:max_retry]
        raise "max_retry (#{@retry_count}) reached, disconnecting"
      end
      if srv_list = opts[:fallback_servers]
        @server_to_select ||= 0
        idex = @server_to_select % (srv_list.size + 1)
        if idex != 0
          try = srv_list[idex - 1]
          try_host = try[:host] || AMQP.settings[:host]
          try_port = try[:port] || AMQP.settings[:port]
        end
        @server_to_select += 1
      end      
      @retry_count += 1
      [try_host, try_port]
    end

.notes https://github.com/brontes3d/amqp/blob/master/lib/amqp/client.rb#L215

!SLIDE[bg=images/sunset.jpg] align-left
### Moment of Reflection

<br/><br/><br/><br/><br/><br/><br/>
<br/><br/><br/><br/><br/><br/>

## Did the tools fail us?
## Did we fail at using them?

.notes stray from best practices leads to re-writing things from scratch. leads to being on an island

!SLIDE[bg=/images/engineyardcloud.png]
### Trains
### ... and Resque

!SLIDE
### Boot an EC2 Server

    @@@ ruby
    class InstanceProvision

      def self.perform(instance_id)
        instance = Instance.find(instance_id)

        fog = Fog::Compute.new(...)
        server = fog.servers.create(...)
        instance.amazon_id = server.id

        while(!server.ready?)
          sleep 1
          server.reload
        end

        instance.attach_ip!
        ...

!SLIDE
### Extractable?

    @@@ ruby
    class InstanceProvision

      def self.perform(aws_creds, create_params, callback_url)
        fog = Fog::Compute.new(aws_creds)
        server = fog.servers.create(create_params)
        API.post(callback_url, :instance_amazon_id => server.id)

        while(!server.ready?)
          sleep 1
          server.reload
        end

        ip = fog.ips.create!
        ip.server = server
        API.post(callback_url, :attached_ip_amazon_id => ip.id)
        ...

!SLIDE
### Generalizable?

    @@@ ruby
    class MethodCalling
      def self.perform(class_str, method, id, *args)
        model_class = Object.const_get(class_str)
        model = model_class.find(id)
        model.send(method, *args)
      end
    end

    class Instance
      def provision
        Resque.enqueue(MethodCalling, Instance, :provision!, id)
      end

      def provision!
        #actually do it
      end
    end

!SLIDE
### Async

    @@@ ruby
    require 'async'
    require 'async/resque'
    Async.backend = Async::ResqueBackend

    class Instance < ActiveRecord::Base
      def provision(*args)
        Async.run{ provision_now(*args)}
      end
      def provision_now(*args)
        #actually do it
      end
    end

## `github.com/engineyard/async`

!SLIDE[bg=images/instancehang.png]
&nbsp;

.notes We have customers complaining

!SLIDE[bg=images/resquehang.png]
&nbsp;

.notes We would have jobs fail, and have to go in and read the code of this method body, and figure out where it failed... and try to fix it. But is the job still running? Did the job throw an exception?

!SLIDE
### Make a Resque Plugin

    @@@ ruby
    class InstanceProvision
      extend Resque::Plugins::JobTracking

      def self.track(instance_id, opts)
        i = Instance.find(instance_id)
        ["Account:#{i.account_id}",
         "Instance:#{instance_id}"]
      end

      def self.perform(instance_id, opts)
        #do stuff
      end
    end

## `github.com/engineyard/resque-job-tracking`

!SLIDE
### Helps a little?

    @@@ ruby
    InstanceProvision.pending_jobs("Instance:532")

    InstanceProvision.failed_jobs("Account:121")

!SLIDE[bg=images/job_dependencies.png]
### Jobs Dependencies

!SLIDE
### Make another

    @@@ ruby
    class Sandwich
      extend Resque::Plugins::Delegation

      def self.steps(tomato_color, cheese_please, cheesemaker)
        step "fetch a", :tomato do
          depend_on(Tomato, tomato_color)
        end
        step "slice the ", :tomato, " and make", :tomato_slices do |tomato|
          tomato.split(",")
        end
        step "fetch the", :cheese_slices do
          if cheese_please
            depend_on(Cheese, cheesemaker)
            ...

## `github.com/engineyard/resque-delegation`

!SLIDE
### Desperation?

    @@@ ruby
    class ResqueJob < ActiveRecord::Base
    end

&nbsp;

    @@@ ruby
    class AbstractJob

      def self.store_meta(meta)
        meta_id = meta["meta_id"]
        ResqueJob.create!(meta.slice(
          "meta_id", "job_class",
          "enqueued_at", "started_at", "finished_at"))
        super(meta)
      end

    ...

!SLIDE
### Maybe we just need better logging?

<h2><iframe width="640" height="360" src="http://www.youtube.com/embed/NpTT30wLL-w?rel=0" frameborder="0" allowfullscreen></iframe></h2>

## `http://youtu.be/NpTT30wLL-w`

!SLIDE
### More Resque Plugins...

    @@@ ruby
    class MyJob
      extend Resque::Plugins::UniqueJob

      def self.perform(*args)
        #do stuff
      end
    end

## `github.com/engineyard/resque-unique-job`

!SLIDE
### Sidekiq doesn't use Resque plugins
(picture of Jim and Ryan)

!SLIDE
### Data belongs in a database (not redis)

    @@@ ruby
    class InstanceProvision < ActiveRecord::Base
      belongs_to :instance

      def run(instance_id)
        fog = Fog::Compute.new(...)
        server = fog.servers.create(...)
        instance.amazon_id = server.id

        while(!server.ready?)
          sleep 1
          server.reload
        end

        instance.attach_ip!
        ...

!SLIDE
# `started_at`
# `finished_at`
# `state`

!SLIDE
### Idempotent

    @@@ ruby
    class InstanceProvision < ActiveRecord::Base
      belongs_to :instance

      def run(instance_id)
        with_lock do
          if self.state == "running"
            raise
          else
            self.state = "running"
            self.started_at = Time.now
            save!
          end
        end
        ...

!SLIDE
### Model Intent
(picture of Josh)

!SLIDE
### Types of Reliability

!SLIDE
### Monitoring Resque

.notes graceful restart
.notes kill old dead things

!SLIDE
### Monitor with God

    @@@ ruby
    5.times do |n|
      God.watch do |w|
        w.name     = "resque-#{num}"
        w.group    = 'resque'
        w.interval = 30.seconds
        w.log      = "#{app_root}/log/worker.#{num}.log"
        w.dir      = app_root
        w.env      = {
          "GOD_WATCH"   => w.name,
          "QUEUE"       => '*'
        }
        w.start    = "bundle exec rake --trace resque:work"
      ...

# `godrb.com`

!SLIDE
### Or Daemons

    @@@ ruby
    require 'daemons'

    options = {
      :app_name => "worker",
      :log_output => true,
      :backtrace => true,
      :dir_mode => :normal,
      :dir => File.expand_path('../../tmp/pids',  __FILE__),
      :log_dir => File.expand_path('../../log',  __FILE__),
      :multiple => true,
      :monitor => true
    }

    Daemons.run(File.expand_path('../worker',  __FILE__), options)

# `daemons.rubyforge.org`

!SLIDE
### Or Don't?

![](images/torquebox.jpg)

# `torquebox.org`

!SLIDE[bg=images/chris.jpg]
&nbsp;

!SLIDE
### Resque Event Loop

    @@@ ruby
    def work(interval = 5, &block)
      loop do
        run_hook :before_fork, job

        if @child = fork
          procline "Forked #{@child} at #{Time.now.to_i}"
          Process.wait
        else
          procline "Processing #{job.queue} since #{Time.now.to_i}"
          perform(job, &block)
          exit! unless @cant_fork
        end
      end

`github.com/defunkt/resque/blob/master/lib/resque/worker.rb`

!SLIDE
### EventMachine

    @@@ C
    void EventMachine_t::Run()
      //Epoll and Kqueue stuff..
      ...

      while (true) {
        _UpdateTime();
        _RunTimers();

        _AddNewDescriptors();
        _ModifyDescriptors();

        _RunOnce();
        if (bTerminateSignalReceived)
          break;
      }
    }

`github.com/eventmachine/eventmachine/blob/master/ext/em.cpp`


!SLIDE
### EM.next_tick

    @@@ ruby
    require 'eventmachine'
    EM.run {
      EM.start_server(host, port, self)
    }

    EM.next_tick{ puts "do something" }


!SLIDE
### Threads

    @@@ ruby
    class Sidekiq::Manager
      include Celluloid
      ???

    class Sidekiq::Fetcher
      include Celluloid
      ???

    class Sidekiq::Processor
      include Celluloid
      ???

# `sidekiq.org`
## `github.com/celluloid/celluloid`


!SLIDE
### Resque graceful restart

!SLIDE
### Push a nil

!SLIDE
### Do it Yourself

!SLIDE
### DIY graceful restart

!SLIDE
### DIY Redis Queue

    @@@ ruby
    class InvoiceProcessingTask

      def self.enq_task(task_id, invoice_id)
        REDIS.rpush("tasks:#{invoice_id}", task_id)
        REDIS.rpush("invoices", invoice_id)
      end

      def self.process_invoices!
        while(invoice_id = REDIS.lpop("invoices"))
          process_tasks!(invoice_id)
        end
      end

      def self.process_tasks!(invoice_id)
        while(task_id = REDIS.lpop("tasks:#{invoice_id}"))
          if task = InvoiceProcessingTask.find_by_id(task_id)
            task.process!
          end
        end
      end

!SLIDE
### Even Resque maintainers don't always use Resque

    @@@ ruby
    module BundlerApi
      class ConsumerPool

        def enq(job)
          @queue.enq(job)
        end

        def create_thread
          Thread.new {
            loop do
              job = @queue.deq
              job.run

.notes https://github.com/hone/bundler-api-replay/blob/master/lib/bundler_api/consumer_pool.rb

!SLIDE
### Conclusions?

!SLIDE
# Pick the right tool for the job?

!SLIDE
# Understand your tradeoffs?

!SLIDE
# Know where you fail and compensate?

!SLIDE
### Avoid Delayed::Job

(picture of evan)

`github.com/ryandotsmith/queue_classic`

!SLIDE
# Questions?
