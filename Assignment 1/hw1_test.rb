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
    # Counter to abort if we get caught in an infinite loop.
    # That's probably unnecessary since we raise an error
    # upon seeing duplicate words, but it doesn't hurt.
    i = 0
    found_words = []
    while (found_words.length < 9 && i < 100)
      prompt = r.readpartial(2048)
      puts prompt
      word = find_target_word(prompt)
      raise "Word \"#{word}\" was given multiple times." if found_words.include?(word)
      found_words.push(word)
      sleep(delay)
      w.puts(word)
      ++i
    end

    raise "Unable to find all words." unless found_words.length == 9
    prompt = r.readpartial(2048)

    # We should see two numbers
    match_result = prompt.scan(/[0-9]+/).map{|val| val.to_i }

    raise "Unable to find two time values. Found: #{match_result.inspect}" unless match_result.length == 2
    puts "Success!"
    match_result
  }
end

hw1_test(ARGV.first)
