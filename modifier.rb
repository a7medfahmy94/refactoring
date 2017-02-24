require File.expand_path('lib/combiner', File.dirname(__FILE__))
require File.expand_path('lib/helper', File.dirname(__FILE__))
require 'csv'
include Helper

class Modifier
  KEYWORD_UNIQUE_ID = 'Keyword Unique ID'.freeze
  LAST_VALUE_WINS = ['Account ID', 'Account Name', 'Campaign', 'Ad Group', 'Keyword', 'Keyword Type', 'Subid', 'Paused', 'Max CPC', 'Keyword Unique ID', 'ACCOUNT', 'CAMPAIGN', 'BRAND', 'BRAND+CATEGORY', 'ADGROUP', 'KEYWORD'].freeze
  LAST_REAL_VALUE_WINS = ['Last Avg CPC', 'Last Avg Pos'].freeze
  INT_VALUES = ['Clicks', 'Impressions', 'ACCOUNT - Clicks', 'CAMPAIGN - Clicks', 'BRAND - Clicks', 'BRAND+CATEGORY - Clicks', 'ADGROUP - Clicks', 'KEYWORD - Clicks'].freeze
  FLOAT_VALUES = ['Avg CPC', 'CTR', 'Est EPC', 'newBid', 'Costs', 'Avg Pos'].freeze

  DEFAULT_CSV_OPTIONS = { col_sep: "\t", headers: :first_row }.freeze

  LINES_PER_FILE = 120_000

  def initialize(saleamount_factor, cancellation_factor)
    @saleamount_factor = saleamount_factor
    @cancellation_factor = cancellation_factor
  end

  def modify(_output, input)
    input = sort(input)

    input_enumerator = lazy_read(input)

    combiner = Combiner.new do |value|
      value[KEYWORD_UNIQUE_ID]
    end.combine(input_enumerator)

    merger = Enumerator.new do |yielder|
      combiner.each do |list_of_rows|
        merged = combine_hashes(list_of_rows)
        yielder.yield(combine_values(merged))
      end
    end
    write_to_files
  end

  private

  # Write output to multiple files if needed
  # each file shall have at most LINES_PER_FILE lines in it
  def write_to_files
    done = false
    file_index = 0
    file_name = output.gsub('.txt', '')
    until done
      CSV.open(file_name + "_#{file_index}.txt", 'wb', col_sep: "\t", headers: :first_row, row_sep: "\r\n") do |csv|
        headers_written = false
        line_count = 0
        while line_count < LINES_PER_FILE
          begin
            merged = merger.next
            unless headers_written
              csv << merged.keys
              headers_written = true
              line_count += 1
            end
            csv << merged
            line_count += 1
          rescue StopIteration
            done = true
            break
          end
        end
        file_index += 1
      end
    end
  end

  def combine(merged)
    result = []
    merged.each do |_, hash|
      result << combine_values(hash)
    end
    result
  end

  def combine_values(hash)
    LAST_VALUE_WINS.each do |key|
      hash[key] = hash[key].last
    end
    LAST_REAL_VALUE_WINS.each do |key|
      hash[key] = hash[key].select { |v| !(v.nil? || v.zero? || v == '0' || v == '') }.last
    end
    INT_VALUES.each do |key|
      hash[key] = hash[key][0].to_s
    end
    FLOAT_VALUES.each do |key|
      hash[key] = hash[key][0].from_german_to_f.to_german_s
    end
    ['number of commissions'].each do |key|
      hash[key] = (@cancellation_factor * hash[key][0].from_german_to_f).to_german_s
    end
    ['Commission Value', 'ACCOUNT - Commission Value', 'CAMPAIGN - Commission Value', 'BRAND - Commission Value', 'BRAND+CATEGORY - Commission Value', 'ADGROUP - Commission Value', 'KEYWORD - Commission Value'].each do |key|
      hash[key] = (@cancellation_factor * @saleamount_factor * hash[key][0].from_german_to_f).to_german_s
    end
    hash
  end

  def combine_hashes(list_of_rows)
    keys = []
    list_of_rows.each do |row|
      next if row.nil?
      row.headers.each do |key|
        keys << key
      end
    end
    result = {}
    keys.each do |key|
      result[key] = []
      list_of_rows.each do |row|
        result[key] << (row.nil? ? nil : row[key])
      end
    end
    result
  end

  def parse(file)
    CSV.read(file, DEFAULT_CSV_OPTIONS)
  end

  def lazy_read(file)
    Enumerator.new do |yielder|
      CSV.foreach(file, DEFAULT_CSV_OPTIONS) do |row|
        yielder.yield(row)
      end
    end
  end

  def write(content, headers, output)
    CSV.open(output, 'wb', col_sep: "\t", headers: :first_row, row_sep: "\r\n") do |csv|
      csv << headers
      content.each do |row|
        csv << row
      end
    end
  end

  def sort(file)
    output = "#{file}.sorted"
    content_as_table = parse(file)
    headers = content_as_table.headers
    index_of_key = headers.index('Clicks')
    content = content_as_table.sort_by { |a| -a[index_of_key].to_i }
    write(content, headers, output)
    output
  end
end

modified = input = latest_file_in_dir('performance', 'data')
modification_factor = 1
cancellaction_factor = 0.4
modifier = Modifier.new(modification_factor, cancellaction_factor)
modifier.modify(modified, input)

puts 'DONE modifying'
