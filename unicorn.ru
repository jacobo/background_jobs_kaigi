#Save this file as example.ru
#In one terminal run: unicorn example.ru
#In another run: curl -v localhost:8080

class CleverMailSender
  class << self; attr_accessor :emails_to_send; end
  self.emails_to_send = []
  class BodyProxy
    def initialize(body)
      @body = body
    end
    def each
      @body.each{|x| yield x}
      while(email = CleverMailSender.emails_to_send.pop)
        puts "sending e-mail: #{email}"
        5.times{|x| puts x; sleep 0.5}
        puts "sent"
      end
    end
  end
  def initialize(app)
    @app = app
  end
  def call(env)
    status, headers, body = @app.call(env)
    unless headers["Content-Length"]
      content_length = 0
      body = body.map{|x| content_length += x.to_s.bytesize; x.to_s}
      headers["Content-Length"] = content_length.to_s
    end
    [status, headers, BodyProxy.new(body)]
  end
end

use CleverMailSender
run lambda{ |env|
  CleverMailSender.emails_to_send << "Hi Mom"
  [200, {"Content-Type" => "text/html"}, ["Hello World\n"]]
}
