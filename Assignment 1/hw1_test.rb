require 'pty'
require 'pry'

@words = %w[The quick brown fox jumps over the lazy dog]
@found_words = []

def hw1_test(directory)
  @original_directory = Dir.pwd
  Dir.chdir(directory) do
    begin
      check_for_makefile
      attempt_compile
      play_game(0)
    rescue => e
      `rm #{@binary}` unless @binary.nil?
      raise e
    end
    `rm #{@binary}`
  end
end

def check_for_makefile
  makefiles = Dir.entries('.').select{|file|
    file == 'makefile' || file == 'Makefile'
  }

  raise "Makefile not found" if makefiles.length != 1
end

def attempt_compile
  existing_files = Dir.entries('.')
  make_output = `make`
  puts "Compilation output: #{make_output}"
  @binary = (Dir.entries('.') - existing_files).first
end

def find_target_word(prompt)
  @words.each do |word|
    # This is one of those lines that makes me wonder
    # if I'm a bad programmer
    return word if prompt.end_with?(" #{word}",
      "#{word}:",
      "#{word}: ",
      "#{word}: \n",
      "#{word}\n",
      "#{word}:\n")
  end

  raise "Word not found. Prompt:\n#{prompt}"
end

def play_game(delay)
  delay ||= 0
  
  PTY.spawn("./#{@binary}"){|r, w, pid|
    word = find_target_word(r.readpartial(2048))
    puts "Found: #{word}"
  }
end

hw1_test(ARGV.first)
