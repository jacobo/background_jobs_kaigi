!SLIDE
### Jacob Burkhart
<br/><br/><br/><br/>
<br/><br/><br/><br/>
<br/><br/><br/><br/><br/>
## @beanstalksurf

!SLIDE[bg=pictures/engineyard.png]
# &nbsp;&nbsp;&nbsp; Engine Yard

!SLIDE
### How to Fail at Background Jobs

<br/><br/><br/><br/><br/><br/><br/>

## `jacobo.github.com/background_jobs`

!SLIDE
### About Failure

!SLIDE
# How to Fail at shipping built in support with Background Jobs in Rails 4

!SLIDE
# Fail at the API

!SLIDE
# Fail at Marshaling

!SLIDE
# Solving the wrong problem

Are we trying to:

Provide a standard abstraction for all queing systems that integrate with Rails
OR
Make sure that sending e-mail does not interfere with web response times

!SLIDE
### A story about Digital Oral Scanning

(and premature optimization)

(in 2008?)
(before resque)

First commit to my AMQP stuff: Aug 24, 2009
First commit to Resque: Aug 11, 2009

"We're going to process thousands of scans a day" (TODO: ask rajiv if he can remember a real number)

Workling, first commit in: Oct 17, 2008
https://github.com/purzelrakete/workling
https://github.com/elecnix/workling

you read these twitter blogs...
https://github.com/starling/starling

!SLIDE
### Enterprise Message Qs

clustering, failover

TODO: what's the name of that unix daemon for reliable messaging?

So then I come to Engine Yard

And the messaging server crashing is the least of our concerns

Before I'd ever heard of zeroMQ:
  there was Spread:
  http://www.spread.org/index.html

!SLIDE
### Reliable Messaging

!SLIDE
### Resque at Engine Yard

!SLIDE
### Job Failures

!SLIDE
### The abstraction paradox

On one side, we think "the message Q should do everything for us", and so we write resque plugins

http://rubygems.org/search?utf8=%E2%9C%93&query=resque

Displaying gems 1 - 30 of 213 in total

We did this in AWSM and ended up with resque lockin

And testing Sucked!

But it was really just me "failing at background jobs"

(code snippet of complicated resQ mock)

Should probably get Josh to explain Resque.inline

#Even the author of resque, doesn't always use resque!














