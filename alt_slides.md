

So the review of Rails 4 Q leads to the question of what's in scope for Rails Messaging

Which leads to the question of what's in scope for this presentation

And I'm afraid there are far too many things that we just don't have time for

So here's what I think I might have time left to cover:

  Reliability: How much do you trust you Queing system?

  Maybe the ideal Q system would provide an API like this?

    class MyJob
      idempotent true
      priority :medium
      retriable true
      timeout_before_failure 10.minutes
      report_timeouts_to_airbrake false
      timeout_before_retry 30.minutes
      max_retries 10
      unique_constraint lambda{|args| args }
      lock_based_on lambda{|args| args.first }

A summary of message Qs

  https://github.com/kookster/activemessaging

Job tracking:
    

Choosing the right layer:
    (picture of the layers and what you might put at each layer)

    premature abstraction with lots of resque plugins

    build on top of thing with my own enQ-ing DSL

Reliability:
    if a workers crashes will messages be retried
      examples:
        sidekiq sometimes depending on the type of crash, sidekiq Pro more often
        maybe there are some resque extensions for this?
        RabbitMQ (if using acks)

    if the message Q crashes will the system continue to function without dropping any jobs
      (assumes the message Q runs on multiple boxes)

      examples:
        RabbitMQ (if using durable Qs and durable messages)
        maybe? ActiveMQ?
        maybe? Q classic + postgres?
        maybe? redis based Qs with slaves?

  OR
    maybe you don't rely on your Q being reliable:

      database table called invoice_processing_tasks
        with state
        enQ invoice_processing_tasks
        periodically (maybe even manually?) check for old tasks that havn't processed
          OR, even have a cron that checks for them and re-enQs them
        make your tasks idempotent so that if re-run they no-op
    