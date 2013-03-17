#Save this file as hax_background_jobs_with_threads.ru
#In one terminal run: rackup hax_background_jobs_with_threads.ru
#In another run: curl -v localhost:9292

class CleverMailSender
  def self.send_email(email)
    Thread.new do
      puts "sending e-mail: #{email}"
      5.times{|x| puts x; sleep 0.5}
      puts "sent"
    end
  end
end

run lambda{ |env|
  CleverMailSender.send_email "Hi Mom"
  [200, {"Content-Type" => "text/html"}, ["Hello World\n"]]
}
