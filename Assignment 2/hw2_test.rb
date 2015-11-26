require 'pty'
require 'pry'
require 'timeout'

require_relative '../test_framework'
require_relative 'private_tests'

hw2_test = ->(directory) {
  Dir.chdir(directory) do
    begin
      compilation_result = attempt_compile
      @binary = compilation_result[:binary]

      test

      if compilation_result[:output].split("\n").length > 1
        raise "Compiler output found: #{compilation_result[:output]}"
      end
    rescue => e
      unless e.is_a?(NameError)
        `rm #{@binary}` unless @binary.nil?
        raise e
      end
    end
    `rm #{@binary}`
  end

  puts 'SUCCESS!'
}

def test(nocmd=false)
    nonneg = '([^-]|^)'

    # For the public tests, we'll use the examples from the assignment spec
    run(%w(4 4 a8), /#{nonneg}12\.0/, nocmd)
    run(%w(4 4 1af), /-15\.5/, nocmd)
    run(%w(4 4 af), /#{nonneg}15\.5/, nocmd)
    run(%w(3 3 3c), /[Nn]a[Nn]/, nocmd)
    run(%w(3 3 38), /#{nonneg}[Ii][Nn][Ff]/, nocmd)
    run(%w(3 3 78), /-[Ii][Nn][Ff]/, nocmd)
    run(%w(3 3 26), /#{nonneg}3\.5/, nocmd)
    run(%w(3 3 18), /#{nonneg}1\.0/, nocmd)
    run(%w(3 3 3f), /#{nonneg}[Nn]a[Nn]/, nocmd)
    run(%w(3 3 37), /#{nonneg}15\.0/, nocmd)

    private_tests(nocmd)
end

def run(inputs, expected, nocmd=false)
  command = "./#{@binary}"
  input_string = ''
  inputs.each do |i|
    input_string += i.to_s + ' '
  end
  
  if nocmd
    output = run_no_cmd(command, input_string, 10)
  else
    command += " #{input_string}"
    output = run_with_timeout(command)
  end
  
  #throw "Expected #{expected.to_s} but found #{output}" if output.match(expected).nil?
  puts "Expected #{expected.to_s} but found #{output}" if output.match(expected).nil?
end

def run_no_cmd(command, input_string, timeout=10)
  output = ''
  PTY.spawn(command){|r, w, pid|
    begin
      Timeout.timeout(15) do
        put_line_with_delay(w, input_string)
        output = get_line_with_delay(r)
      end
    rescue Timeout::Error => e
      PTY.kill(-15, pid)
      raise e
    end
  }
  output
end

#run_on_directory(hw2_test, ARGV.first)
#hw2_test.call(ARGV.first)
@binary = ARGV.first
test(ARGV.length > 1 && ARGV[1] == 'true')
