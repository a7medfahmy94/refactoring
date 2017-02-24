require File.expand_path('spec_helper', File.dirname(__FILE__))
require File.expand_path('../modifier', File.dirname(__FILE__))
require 'fileutils'

describe Modifier do
  let(:modifier) {Modifier.new(1, 0.4)}
  after(:all) do
    path = File.expand_path('spec_files', File.dirname(__FILE__))
    FileUtils.rm("#{path}/2016-02-20_performance.txt.sorted")
    FileUtils.rm("#{path}/result_0.txt")
  end
  it "should produce the correct file" do
    path = File.expand_path('spec_files', File.dirname(__FILE__))
    input = "#{path}/2016-02-20_performance.txt"
    output = "#{path}/result.txt"
    modifier.modify(output, input)
    expect(File.read("#{path}/result_0.txt")).to eq(File.read("#{path}/expected.txt"))
  end
end
