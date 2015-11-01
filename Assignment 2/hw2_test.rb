require 'pty'
require 'pry'
require 'timeout'

require_relative '../test_framework'

hw2_test = ->(directory) {
  Dir.chdir(directory) do
    begin
      @binary = attempt_compile

    # For the public tests, we'll use the examples from the assignment spec
    run(%w(4 4 a8), '12.0')
    run(%w(4 4 1af), '-15.5')
    run(%w(4 4 af), '15.5')
    run(%w(3 3 3c), 'NaN')
    run(%w(3 3 38), '+inf')
    run(%w(3 3 78), '-inf')
    run(%w(3 3 26), '3.5')
    run(%w(3 3 18), '1.0')
    run(%w(3 3 3f), 'NaN')
    run(%w(3 3 37), '15.0')
    rescue => e
      `rm #{@binary}` unless @binary.nil?
      raise e
    end
    `rm #{@binary}`
  end

  puts 'SUCCESS!'
}

def run(inputs, expected)
  command = "./#{@binary} "
  inputs.each do |i|
    command += i.to_s + ' '
  end


  output = run_with_timeout(command)
  
  throw "Expected #{expected} but found #{output}" unless output.include?(expected)  
end

run_on_directory(hw2_test, ARGV.first)
#hw2_test.call(ARGV.first)
