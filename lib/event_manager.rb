require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

# this encapsulates the code for the tutorial to clean up zipcodes, pull officials, and create letters
def exercise_output(contents)
  contents.each do |row|
    id = row[0]
    name = row[:first_name]
    zipcode = clean_zipcode(row[:zipcode])
    legislators = legislators_by_zipcode(zipcode)

    form_letter = erb_template.result(binding)

    save_thank_you_letter(id, form_letter)
  end
end

puts 'EventManager initialized.'

# pulls in file using CSV ruby tool providing built in fuctions e.g., remove first row and use symbols
contents = CSV.open(
  '../event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('../form_letter.erb')
erb_template = ERB.new template_letter

# pulls phone numbers from input file and normalizes by removing undesired characters
# runs normalized numbers through check method and puts first name with number
def phone_numbers(contents)
  contents.each do |row|
    phone_number = row[:homephone].tr('()-." "', '')
    puts "#{check_phone_number(phone_number)}: #{row[:first_name]}"
  end
end

# validates and corrects phone numbers, is called by phone_numbers()
def check_phone_number(phone_number)
  case
  when phone_number.length < 10 || phone_number.length > 11
    print 'invalid number'
  when phone_number.length == 11
    phone_number.start_with?('1') ? (print phone_number[1..-1]) : (print 'invalid number')
  else
    print phone_number
  end
end

# pull string date/time from file and converts mm/dd/yy to yyyy-dd-mm and hh
# pull the hour and add to an array, then iterate over array to add frequency of hours to hash
# hash shows key (hour) and its frequency
def registration_hour(contents)
  time_array = []
  contents.each do |row|
    date_time = DateTime.strptime(row[:regdate], '%m/%d/%y %k')
    time_array << date_time.hour
  end
  
  hour_dist = Hash.new(0)
  time_array.each do |hour|
    hour_dist[hour] += 1
  end
  puts hour_dist
end

# also converts string date from file to Ruby date and then pulls the day of the week
# day of week added to array that is iterated over to add frequency of days to hash
def registration_day(contents)
  day_array = []
  contents.each do |row|
    date_time = DateTime.strptime(row[:regdate], '%m/%d/%y')
    day_array << date_time.strftime('%A')
  end

  day_dist = Hash.new(0)
  day_array.each do |day|
    day_dist[day] += 1
  end
  puts day_dist
end

# can only run one method at a time. The file closes after the first one and won't run a second time.
puts 'The phone numbers are as follows:'
phone_numbers(contents)
# puts 'The registration hour frequency is as follows:'
# registration_hour(contents)
# puts 'The registration day frequency is as follows:'
# registration_day(contents)