
def find_makefile
  makefiles = Dir.entries('.').select{|file|
    file == 'makefile' || file == 'Makefile'
  }

  raise "Makefile not found" if makefiles.length != 1

  makefiles.first
end

def run_with_timeout(command, timeout = 5)
  # via http://stackoverflow.com/questions/12189904/fork-child-process-with-timeout-and-capture-output

  pipe = IO.popen("#{command} 2>&1", 'r')

  output = ''
  begin
    Timeout.timeout(timeout) do
      Process.waitpid2(pipe.pid)
      output = pipe.gets(nil)
    end
  rescue Timeout::Error => e
    Process.kill('-9', pipe.pid)
  end


  pipe.close
  output
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
  {
    binary: binary,
    output: make_output
  }
end

def find_binary_name(makefile)
  compilation_statements = []
  File.open(makefile) do |f|
    f.each_line{|line|
      # Remove leading whitespace
      stripped = line.lstrip
      compilation_statements.push(stripped) if stripped.start_with?('gcc') || stripped.start_with?('$(CC)') || stripped.start_with?('cc')
    }
  end

  raise "No compilation statement found" if compilation_statements.length == 0

  compilation_statements.each do |l|
    output_match = l.match(/-o +[^ ]+/)
    return output_match.to_s.split(' ').last unless output_match.nil?
  end

  'a.out'
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
  elsif file.end_with?('.tar')
    command = "tar -xvf #{escaped_filename(file)}"
  else
    raise "Unrecognized filetype: #{file}"
  end

  run_with_timeout(command, 10)
end

def escaped_filename(file)
  file.gsub(" ", "\\ ").gsub('(', '\(').gsub(')', '\)')
end

def run_on_directory(test, dir)
    # Open output file for results
    successes = File.open("successes", "w")
    failures = File.open("failures", "w")
    compiler_output = File.open("compiler_output", "w")

    Dir.chdir(dir) do
      zips = Dir.entries('.').select{|file|
        !file.match(/["zip""rar""tar.gz""tar"]\Z/).nil?
      }

      existing_directories = Dir.glob("**/")
      existing_files = Dir.entries('.')
      
      zips.each{|file|
        failed = false
        
        begin
          decompress(file)
          
          # Get new directory
          new_directories = Dir.glob("**/").select{|d|
            !existing_directories.include?(d)
          }

          filtered_directories = new_directories.select{|d|
            !d.start_with?('__MACOSX')
          }

          new_files = Dir.entries('.').select{|file|
            !existing_files.include?(file)
          }
          
          throw "Unable to find new directory" if new_directories.length != 1 && new_files.length == 0

          test.call(filtered_directories.length == 1 ? filtered_directories.first : '.')
        rescue => e
          if e.to_s.match(/Compiler output found/).nil?
            failures.puts("#{file},#{e.inspect}")
            failed = true
          else
            compiler_output.puts("#{file}\n\t#{e.inspect}")
          end
        end

        new_directories.each{|dir|
          run_with_timeout("rm -rf #{dir}", 10)
        } unless new_directories.nil?

        new_files.each{|file|
          run_with_timeout("rm -rf #{file}")
        } unless new_files.nil?

        successes.puts(file) unless failed
      }
    end

    successes.close
    failures.close
    compiler_output.close
end
