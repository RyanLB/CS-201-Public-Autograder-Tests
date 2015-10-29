
def find_makefile
  makefiles = Dir.entries('.').select{|file|
    file == 'makefile' || file == 'Makefile'
  }

  raise "Makefile not found" if makefiles.length != 1

  makefiles.first
end

def run_with_timeout(command, timeout = 5)
  pid = Process.spawn(command)
  begin
    Timeout.timeout(timeout) do
      Process.wait(pid)
    end
  rescue Timeout::Error => e
    Process.kill(-15, pid)
    raise e
  end
end

def attempt_compile
  makefile = find_makefile
  binary = find_binary_name(makefile)
  existing_files = Dir.entries('.')

  # Remove the binary if it already exists
  if existing_files.include?(binary)
    puts "DELETING #{binary}"
    run_with_timeout("rm -f #{binary}")
  end

  make_output = run_with_timeout('make')
  raise "Unable to find binary" unless Dir.entries('.').include?(binary)
  binary
end

def find_binary_name(makefile)
  compilation_statements = []
  File.open(makefile) do |f|
    f.each_line{|line|
      # Remove leading whitespace
      stripped = line.lstrip
      compilation_statements.push(stripped) if stripped.start_with?('gcc')
    }
  end

  raise "No compilation statement found" if compilation_statements.length == 0

  compilation_statements.each do |l|
    output_match = l.match(/-o +[^ ]+/)
    return output_match.to_s.split(' ').last unless output_match.nil?
  end

  raise "Unable to find binary name"
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

def decompress(file)
  if file.end_with?('.zip')
    command = "unzip #{escaped_filename(file)}"
  elsif file.end_with?('.rar')
    command = "unrar e #{escaped_filename(file)}"
  elsif file.end_with?('.tar.gz')
    command = "tar -xzvf #{escaped_filename(file)}"
  else
    raise "Unrecognized filetype: #{file}"
  end

  run_with_timeout(command, 10)
end

def escaped_filename(file)
  file.gsub(" ", "\\ ").gsub('(', '\(').gsub(')', '\)')
end

def run_on_directory(dir)
    # Open output file for results
    successes = File.open("successes", "w")
    failures = File.open("failures", "w")

    Dir.chdir(dir) do
      zips = Dir.entries('.').select{|file|
        !file.match(/.["zip""rar""tar.gz"]\Z/).nil?
      }

      existing_directories = Dir.glob("**/")
      existing_files = Dir.entries('.')
      
      zips.each{|zip|
        failed = false
        
        begin
          decompress(file)
          
          # Get new directory
          new_directories = Dir.glob("**/").select{|dir|
            !existing_directories.include?(dir)
          }

          new_files = Dir.entries('.').select{|file|
            !existing_files.include?(file)
          }
          
          throw "Unable to find new directory" if new_directories.length != 1 && new_files.length == 0

          hw1_test(new_directories.length == 1 ? new_directories.first : '.')
        rescue => e
          failures.puts("#{zip},#{e.inspect}")
          failed = true
        end

        new_directories.each{|dir|
          run_with_timeout("rm -rf #{dir}", 10)
        } unless new_directories.nil?

        new_files.each{|file|
          run_with_timeout("rm -rf #{file}")
        }

        successes.puts(zip) unless failed
      }
    end

    successes.close
    failures.close
end
