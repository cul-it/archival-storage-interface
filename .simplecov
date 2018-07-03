# Configuration for SimpleCov

puts "in .simplecov"

SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new([
                                                                  SimpleCov::Formatter::HTMLFormatter,
#                                                                  SimpleCov::Formatter::CSVFormatter,
                                                                ])

SimpleCov.start 'rails' do
  add_filter '/app/channels/'
  add_filter '/app/mailers/'
  add_filter '/app/jobs/'
end


