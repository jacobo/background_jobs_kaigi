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
### My Failed "Fix"

    @@@ruby
    def pop
      job_data = self.encoder.decode(super)
      job_class = job_data["payloadizer"].constantize
      job_class.job_from_payload(job_data["payload"])
    end

    def push(job)
      payloadizer = (job.respond_to?(:payloadizer) && 
        job.payloadizer) || self.default_payloadizer
      super self.encoder.encode({
        'payloadizer' => payloadizer.unconstantize,
        'payload' => payloadizer.payload_from_job(job)})
    end

## `github.com/rails/rails/pull/9910`

.notes TODO: a pull request with "minimal background jobs system" -OR- a pull request with "all the hooks"... or both?

!SLIDE[bg=images/skimboardfail.jpg]
### Moving on...

!SLIDE
### Let's talk about Teeth

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
<br/>
## `github.com/djabberd/DJabberd`
<br/>
## `xmpp.org/xmpp-protocols/xmpp-extensions`

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
### Bug

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

!SLIDE[bg=images/steep.jpg]
### Generic abstractions are hard

.notes poll vs. push
.notes because workling controls the run loop, we couldn't easily mix with EM-based xmpp
.notes spinning up (and down) an event machine every time you need to send a message is really crappy

!SLIDE
### So Do it Yourself

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

!SLIDE[bg=images/sunset.jpg]
### Moment of Reflection
&nbsp;

.notes stray from best practices leads to re-writing things from scratch. leads to being on an island

!SLIDE
### Daemons

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
### Or God?

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
### Or Torquebox?

![](images/torquebox.jpg)

# `torquebox.org`

!SLIDE[bg=images/chris.jpg]
&nbsp;

!SLIDE
### Event loops

    @@@ ruby
    require 'eventmachine'
    EM.run {
      EM.start_server(host, port, self)
    }
    EM.next_tick{ puts "do something" }

    cli = Sidekiq::CLI.instance
    cli.parse
    cli.run


!SLIDE
### Event Machine

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

<h2><pre>
github.com/eventmachine/eventmachine/
blob/master/ext/em.cpp#L435
</pre></h2>

!SLIDE
### Resque

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

<h2><pre>
github.com/defunkt/resque/
blob/master/lib/resque/worker.rb#L120
</pre></h2>

!SLIDE
### Celluloid / Sidekiq

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
### How about a better event loop in Resque?
(pull request)


!SLIDE[bg=/images/engineyardcloud.png]
### Let's talk about Trains

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
### Extractable to another app?

  Job takes no active record models as args

!SLIDE
### Just an asynchronous method call?

  MethodCalling Job

!SLIDE[bg=images/resquehang.png]
&nbsp;

.notes We would have jobs fail, and have to go in and read the code of this method body, and figure out where it failed... and try to fix it. But is the job still running? Did the job throw an exception?

!SLIDE[bg=images/instancehang.png]
&nbsp;

.notes We have customers complaining

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
### Too much work to refactor all those jobs...

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
### Maybe we just needed better logging?

!SLIDE
### Model Everything!

    @@@ ruby
    class InstanceProvision < ActiveRecord::Base
      ...
      Viaduct?

!SLIDE
### Some Resque Plugins are still useful..

    @@@ ruby
    class MyJob
      extend Resque::Plugins::UniqueJob

      def self.perform(*args)
        #do stuff
      end
    end

## `github.com/engineyard/resque-unique-job`

!SLIDE
### Celluloid loves sleeps

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
### Sidekiq doesn't work with all our Resque plugins!
(picture of Jim and Ryan)

!SLIDE
### Data belongs in a database

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
### Idempotence becomes Easier

!SLIDE
### Async

    @@@ ruby
    require 'async'
    require 'async/resque'
    Async.backend = Async::ResqueBackend

    class Invoice < ActiveRecord::Base
      def process(arg)
        Async.run{ process_now(arg)}
      end
      def process_now(arg)
        #actually do it
      end
    end

    invoice.process 123

## `github.com/engineyard/async`

!SLIDE
### InvoiceProcessingTask

    @@@ ruby
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
### BONUS: You don't always need to build a job class

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

!SLIDE
# Questions?
