require_relative 'test_framework'

def filter_successes(successes, directory)
  Dir.chdir(directory) do
    `mkdir successes` unless Dir.entries('.').include?('successes')
    success_files = Dir.entries('.').select{|file|
      successes.include?(file)
    }

    success_files.each do |f|
      `mv #{escaped_filename(f)} successes`
    end
  end
end

def read_successes_from_file(file)
  successes = []

  File.open(file) do |success_file|
    success_file.each_line do |line|
      successes.push(line.chomp("\n"))
    end
  end

  successes
end

filter_successes(read_successes_from_file(ARGV.first), ARGV[1]) unless ARGV.length < 2
