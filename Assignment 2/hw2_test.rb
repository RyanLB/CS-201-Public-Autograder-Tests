require 'pty'
require 'pry'
require 'timeout'

require_relative '../test_framework'
require_relative 'private_tests'

hw2_test = ->(directory) {
  Dir.chdir(directory) do
    nonneg = '([^-]|^)'

    begin
      compilation_result = attempt_compile
      @binary = compilation_result[:binary]

      # For the public tests, we'll use the examples from the assignment spec
      run(%w(4 4 a8), /#{nonneg}12\.0/)
      run(%w(4 4 1af), /-15\.5/)
      run(%w(4 4 af), /#{nonneg}15\.5/)
      run(%w(3 3 3c), /[Nn]a[Nn]/)
      run(%w(3 3 38), /#{nonneg}[Ii][Nn][Ff]/)
      run(%w(3 3 78), /-[Ii][Nn][Ff]/)
      run(%w(3 3 26), /#{nonneg}3\.5/)
      run(%w(3 3 18), /#{nonneg}1\.0/)
      run(%w(3 3 3f), /#{nonneg}[Nn]a[Nn]/)
      run(%w(3 3 37), /#{nonneg}15\.0/)

      private_tests

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

def run(inputs, expected)
  command = "./#{@binary} "
  inputs.each do |i|
    command += i.to_s + ' '
  end


  output = run_with_timeout(command)
  
  throw "Expected #{expected.to_s} but found #{output}" if output.match(expected).nil?
end

run_on_directory(hw2_test, ARGV.first)
#hw2_test.call(ARGV.first)
