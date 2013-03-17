#Save this file as example.ru
#In one terminal run: thin start --rackup example.ru
#In another run: curl -v localhost:3000

class CleverMailSender
  class << self; attr_accessor :emails_to_send; end
  self.emails_to_send = []
  def initialize(app)
    @app = app
  end
  def call(env)
    status, headers, body = @app.call(env)
    EM.next_tick do
      while(email = CleverMailSender.emails_to_send.pop)
        puts "sending e-mail: #{email}"
        5.times{|x| puts x; sleep 0.5}
        puts "sent"
      end
    end
    [status, headers, body]
  end
end

use CleverMailSender
run lambda{ |env|
  CleverMailSender.emails_to_send << "Hi Mom"
  [200, {"Content-Type" => "text/html"}, ["Hello World\n"]]
}
