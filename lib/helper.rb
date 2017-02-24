require 'date'

module Helper
  # Gets the latest data file in a directory matching some name
  # Input:
    # name: partial name of the file, e.g. 'performancedata'
    # dir(optional): the directory in whic to look for files
  def latest_file_in_dir(name,dir="#{ ENV["HOME"] }/workspace")
    files = Dir["#{ dir }/*#{name}*.txt"]

    files.sort_by! do |file|
      last_date = /\d+-\d+-\d+_[[:alpha:]]+\.txt$/.match file
      last_date = last_date.to_s.match /\d+-\d+-\d+/

      date = DateTime.parse(last_date.to_s)
      date
    end

    throw RuntimeError if files.empty?

    files.last
  end
end

class String
	def from_german_to_f
		self.gsub(',', '.').to_f
	end
end

class Float
	def to_german_s
		self.to_s.gsub('.', ',')
	end
end
