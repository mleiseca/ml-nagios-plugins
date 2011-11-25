

require 'mysql' 
require 'optparse'
require 'pp'

# Queries
# Innodb_rows_deleted 196558
# Innodb_rows_inserted 4672974
# Innodb_rows_read 2031268891
# Innodb_rows_updated 25667

CODE={
  :ok=>0,
  :warning=>1,
  :critical=>2,
  :unknown =>3,
  :dependent=>4
};


options = {}

optparse = OptionParser.new do|opts|
  # opts.banner = "Usage: check_mysqld.rb  ..."
  
  
  # This displays the help screen, all programs are
  # assumed to have this option.
  opts.on( '-?', '--help', 'Display this screen' ) do
    puts opts
    exit CODE[:unknown]
  end
  
  options[:host] = 'localhost'
  opts.on( '-h', '--host HOST', 'Host to connect to. Default is localhost' ) do|host|
    options[:host] = host
  end

  options[:user] = nil
  opts.on( '-u', '--user USER', 'User for login' ) do|user|
    options[:user] = user
  end
  
  options[:password] = ''
  opts.on( '-p', '--password PASSWORD', 'Password when connecting to db' ) do|password|
    options[:password] = password
  end
  
  options[:status_variable] = ''
  opts.on( '-s', '--status_variable STATUS_VARIABLE', 'Status variable to monitor' ) do|status_variable|
    options[:status_variable] = status_variable
  end
  
  options[:log_filename] = nil
  opts.on( '-l', '--log_filename LOG_FILENAME', 'Log filename (will default to /tmp/check_mysqld_{STATUS_VARIABLE}_{HOST}.log)' ) do|log_filename|
    options[:log_filename] = log_filename
  end
  
end

optparse.parse!

exit CODE[:unknown] if options[:host].nil?
exit CODE[:unknown] if options[:status_variable].nil?

if options[:log_filename].nil?
  options[:log_filename] = "/tmp/check_mysqld_" << options[:status_variable] << "_" << options[:host] <<  ".log"
end

# pp "Options:", options
# pp "ARGV:", ARGV

# read previously save data
previous_time = nil
previous_value = nil
begin
  File.open(options[:log_filename], "r") do |infile|
    while (line = infile.gets)
      # todo: malformed file
      vals = line.split(/\t/)
      previous_time = vals[0]
      previous_value = vals[1]
    end
  end
rescue => err
  # todo: what if user just doesn't have read access to file?
  # file didn't exist
end

# puts "Previous time: #{previous_time}, previous value: #{previous_value}"

# todo: on connection error
con = Mysql.new(options[:host],options[:user], options[:password])  
rs = con.query('show status')  

current_time = Time.now.getutc.to_i
current_value = nil
rs.each do |row|
  col1 = row[0]
  col2 = row[1]
  if col1 == options[:status_variable]
    current_value = col2
  end
end
# rs.each_hash { |h| puts h['name']}  
con.close

if current_value.nil?
  # todo: error: couldn't find status variable
end

# todo: error writing
File.open(options[:log_filename], 'w') {|f| f.write([current_time,current_value].join("\t")) }


# todo: what to do on boot strapping??
diff_value = current_value.to_i - previous_value.to_i
diff_time = current_time.to_i - previous_time.to_i

# puts "#{diff_value} / #{diff_time} = " << sprintf('%.3f',diff_value.fdiv( diff_time))

# now output the results
print "MYSQL " << "status variable: " << options[:status_variable];
print " " << sprintf('%.3f',diff_value.fdiv( diff_time)) << " per second"
print " |" ; # this is for perf data. Don't have any here, or it would go after this pipe
print "\n";

# end exit
exit CODE[:ok]



