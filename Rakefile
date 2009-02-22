task :default => [:test]

desc "Copy to server"
task :deploy do
  host = ENV['HOST']
  if not host
    puts "Usage: HOST=host rake deploy"
  else
    system "scp -r tracker.rb #{host}:/usr/lib/cgi-bin/tracker.cgi"
    # Edit path to ruby
    system "ssh #{host} \"echo \\\"1s/\\/usr\\/local\\/bin\\/ruby/\\/opt\\/ruby-enterprise-1.8.6-20081215\\/bin\\/ruby\nwq\\\" | ed /usr/lib/cgi-bin/tracker.cgi\""
  end
end

desc "Test"
task :test do
  require 'tracker_test'
end
