!SLIDE
### Jacob Burkhart
<br/><br/><br/><br/>
<br/><br/><br/><br/>
<br/><br/><br/><br/><br/>
## @beanstalksurf

!SLIDE
### Engine Yard
# (Distill)

!SLIDE
### Failure

.notes Failure is a good thing

!SLIDE
# I want to spark conversations

!SLIDE
### How to Fail at Background Jobs

<br/><br/><br/><br/><br/><br/><br/>

## `jacobo.github.com/background_jobs`

!SLIDE
### How to Fail at Background Jobs: Shipping a useful Queuing abstraction with Rails 4

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
### Maybe Rails 4 Q should be more like Rack
(link to pull request)

!SLIDE
### But enough about other people's failures...


!SLIDE
### Let's talk about Teeth

    @@@ ruby
    define_system(:us_adult) do

      common_name "Universal/National System for permanent (adult) dentition"

      upper_right "8", "7", "6", "5", "4", "3", "2", "1"

      upper_left "16", "15", "14", "13", "12", "11", "10", "9"

      lower_right "25", "26", "27", "28", "29", "30", "31", "32"

      lower_left "17", "18", "19", "20", "21", "22", "23", "24"

    end

## github.com/brontes3d/tooth_numbering

!SLIDE
### 2009

!SLIDE
### Workling and Starling

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

!SLIDE[bg=images/worklingrunners.png]
&nbsp;

.notes Brontes fork of workling at: https://github.com/brontes3d/workling

!SLIDE
### Round Peg.
### Square Hole.

!SLIDE
### All you need is Daemons

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

!SLIDE bullets incremental
### Lessons?

* The slippery slope of: "I can fix that"
* Open sourcing it doesn't mean anybody cares

.notes How many of you have said/thought "I can fix background jobs so they don't suck". How many of you have failed? Given up? Because even if you succeed, you still have this monumental task of getting everybody else to use your solution.

!SLIDE
### Reliable Messaging might be a solution.

### Reliable Execution is usually the problem.

.notes so we made sore rabbit was sending and handling messages reliably because we were told this is a feature of rabbit. not because it's something we thought we needed.  In my experience, generally you have many more problems with message execution, than you do with message delivery.

!SLIDE
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

!SLIDE[bg=images/resquehang.png]
&nbsp;

.notes We would have jobs fail, and have to go in and read the code of this method body, and figure out where it failed... and try to fix it. But is the job still running? Did the job throw an exception?

!SLIDE[bg=images/instancehang.png]
&nbsp;

.notes We have customers complaining

!SLIDE[bg=images/instancefail.png]
&nbsp;

!SLIDE
### Make a Resque Plugin

!SLIDE
### Make another Resque Plugin

!SLIDE
### But now we can't upgrade to sidekiq

!SLIDE
### Celluloid (and threads in general) loves sleeps

!SLIDE
### Move to database models

!SLIDE
### Lessons?

???

!SLIDE
### So now I don't put abstractions in Resque, I build them on top

!SLIDE
### Async

!SLIDE
### InvoiceProcessingTask

!SLIDE
### Even Resque maintainers don't always use Resque

!SLIDE
### Work abstractions libraries (and thus Rails 4 Q) should be more like Rack

!SLIDE
# Conclusions?

!SLIDE
# Pick the right tool for the job?
# BUT maintaining a massive polyglot of tools is annoying too!

!SLIDE
# Understand your tradeoffs?

!SLIDE
# Know where you fail and compensate for it?


!SLIDE
### BONUS: You *could* add reliable messaging to anything...

    @@@ perl
      my($mailbox, $private_group) = Spread::connect(
        spread_name => '4444@host.domain.com');

      Spread::multicast($mbox, SAFE_MESS, @joined_groups,
        0, "Important Message");

`search.cpan.org/~jesus/Spread-3.17.4.4/Spread.pm`

`www.spread.org/docs/spread_docs_4/docs/message_types.html`

`rbspread.sourceforge.net`

!SLIDE
# Questions?
