require 'pty'
require 'pry'

@words = %w[The quick brown fox jumps over the lazy dog]

def hw1_test(directory)
  @original_directory = Dir.pwd
  Dir.chdir(directory) do
    begin
      check_for_makefile
      attempt_compile
      first_time = play_game(0)
      second_time = play_game(1)
      raise "Time value did not increase with delay!" unless second_time.first > first_time.first
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

def get_line_with_delay(r)
  # Because Ruby can type much faster than I can, out input
  # and output can get out of sync if we don't add a small delay
  sleep(0.03)  
  r.readpartial(2048)
end

def put_line_with_delay(w, line)
  sleep(0.03)
  w.puts(line)
end

def find_target_word(prompt)
  @words.each do |word|
    unless prompt.match(/(#{word})(:?)[ (\r?\n)]?\Z/).nil?
      #binding.pry
      return word
    end
  end

  raise "Word not found. Prompt:\n#{prompt}"
end

def duplicate_word(found_words, word)
  dup_count = found_words.select{|w| w == word}.length
  if word == "the"
    return (found_words.include?("The") && dup_count > 0) || dup_count > 1
  end
  dup_count > 0
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
      prompt = get_line_with_delay(r)
      puts prompt
      word = find_target_word(prompt)
      raise "Word \"#{word}\" was given multiple times." if duplicate_word(found_words, word)
      found_words.push(word)
      sleep(delay)
      put_line_with_delay(w, word)
      ++i
    end

    raise "Unable to find all words." unless found_words.length == 9
    sleep(1)
    prompt = get_line_with_delay(r)

    # We should see two numbers
    match_result = prompt.scan(/[0-9]+/).map{|val| val.to_i }

    raise "Unable to find time values. Found: #{match_result.inspect}" unless match_result.length == 1 || match_result.length == 2
    puts "Success!"
    return match_result
  }
end

def run_on_directory(dir)
  #hurr
end

# run_on_directory(ARGV.first)

hw1_test(ARGV.first)
