#Save this file as hax_background_jobs_with_celluloid.ru
#In one terminal run: rackup hax_background_jobs_with_celluloid.ru
#In another run: curl -v localhost:9292

require 'celluloid'

class CleverMailSender
  class Sender
    include Celluloid
    def send_email(email)
      puts "sending e-mail: #{email}"
      5.times{|x| puts x; sleep 0.5}
      puts "sent"
    end
  end
  def self.send_email(email)
    @sender ||= Sender.pool(size: 2)
    @sender.async.send_email("Hi Mom")
  end
end

run lambda{ |env|
  5.times do
    CleverMailSender.send_email "Hi Mom"
  end
  [200, {"Content-Type" => "text/html"}, ["Hello World\n"]]
}
