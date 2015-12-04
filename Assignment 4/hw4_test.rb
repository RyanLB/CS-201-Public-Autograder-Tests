require 'pry'
require 'timeout'

require_relative '../test_framework'

def hw4_test(directory)
  Dir.chdir(directory) do
    # Ensure that output hasn't been modified
    File.open('submission.c', "r") do |f|
      f.each_line do |line|
        unless line.match(/printf/).nil? && line.match(/puts/).nil? && line.match(/putc/).nil?
          raise 'Submission attempts to print'
        end
      end
    end

    make_output = run_with_timeout('make')
    if make_output.split("\n").length > 1
      has_compiler_output = true
    end

    raise "Compilation failed" unless Dir.glob("*").include?('main')

    run_output = run_with_timeout('./main')

    # All lines should match
    raise 'Non-matching output found' unless run_output.match(/NO MATCH/).nil?

    last_iteration_start = run_output.index('Test length: 10000000')
    last_iteration = run_output.slice(last_iteration_start..-1).split("\n")
    scalar_cycle_count = last_iteration[1].match(/[0-9]+/).to_s.to_i
    vector_cycle_count = last_iteration[2].match(/[0-9]+/).to_s.to_i
    if (scalar_cycle_count.to_f / vector_cycle_count.to_f) < 20
      raise "Performance goals not met: #{scalar_cycle_count.to_f / vector_cycle_count.to_f}"
    end

    raise "Compiler output found: #{make_output}" if has_compiler_output
  end
end

# Since this assignment uses .c files instead of .zip archives, we'll
# just write a new function.
def hw4_run_on_directory(directory, distro_code_dir)
  # Open output file for results
  successes = File.open("successes", "w")
  failures = File.open("failures", "w")
  compiler_output = File.open("compiler_output", "w")

  Dir.chdir(directory) do
    correctly_named_submissions = Dir.glob("*").select{|f| f.end_with?('submission.c')}
    correctly_named_submissions.each do |submission|
      # Make sandbox directory
      `cp -r #{escaped_filename(distro_code_dir)} sandbox`
      
      begin
        `cp #{escaped_filename(submission)} sandbox/submission.c`
        
        hw4_test('sandbox')
      rescue => e
        if e.to_s.match(/Compiler output found/).nil?
          failures.puts("#{submission},#{e.inspect}")
          failed = true
        else
          compiler_output.puts("#{file}\n\t#{e.inspect}")
        end
      end
      
      `rm -r sandbox`
    end
  end
    
  successes.close
  failures.close
  compiler_output.close
end

hw4_run_on_directory(ARGV.first, ARGV[1])
