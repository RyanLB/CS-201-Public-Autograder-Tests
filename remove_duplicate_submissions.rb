require_relative 'test_framework'
require 'pry'

@dup_num_and_extension = /\([0-9]+\)\.[a-z]+\Z/

def remove_duplicate_submissions(submission_directory)
  Dir.chdir(submission_directory) do
    `mkdir duplicates` unless Dir.glob("**/").include?('duplicates/')

    # Get all entries with "(#)" on the end
    duplicates = files_with_dup_nums
    while (duplicates.length > 0) do
      reps = files_with_same_name(duplicates.first)
      original_filename = original(reps)
      (reps - [last_duplicate(reps)]).each do |rep|
        `mv #{escaped_filename(rep)} duplicates`
      end
      `mv #{escaped_filename(last_duplicate(reps))} #{escaped_filename(original_filename)}`
      duplicates = files_with_dup_nums
    end
  end
end

def files_with_dup_nums
  Dir.glob("*").select{|f| !f.match(@dup_num_and_extension).nil? }
end

def files_with_same_name(filename)
  end_index = filename.rindex(@dup_num_and_extension)
  without_extension = filename.slice(0, end_index)
  Dir.glob("*").select{|f| f.start_with?(without_extension)}
end

def last_duplicate(files)
  with_nums = files.select{|f| !f.match(@dup_num_and_extension).nil?}
  sorted = with_nums.sort_by!{|f|
    # This next line is probably kind of bad
    f.match(@dup_num_and_extension).to_s.match(/[0-9]+/).to_s.to_i
  }
  sorted.last
end

def original(files)
  files.select{|f| f.match(@dup_num_and_extension).nil? }.first
end

remove_duplicate_submissions(ARGV.first)
