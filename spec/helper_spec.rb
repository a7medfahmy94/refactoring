require File.expand_path('spec_helper', File.dirname(__FILE__))
require 'helper'
require 'fileutils'

include Helper
describe Helper do
	context "#latest_file_in_dir" do
		context "when there are no files or directory doesn't exist" do
			it "should throw a runtime error" do
        expect {
          latest_file_in_dir('doesnt_exist')
        }.to throw_symbol(RuntimeError)
        expect {
          latest_file_in_dir('data', "/dont_exist")
        }.to throw_symbol(RuntimeError)
			end
		end
		context "when there files" do
      before(:all) do
        Dir.mkdir 'foo'
        FileUtils.touch('foo/2017-02-20_performance.txt')
        FileUtils.touch('foo/2017-02-21_performance.txt')
        FileUtils.touch('foo/2017-02-22_performance.txt')
      end
      after(:all) do
        FileUtils.rm_rf('foo')
      end
			it "should return the latest" do
        expect(latest_file_in_dir('performance', 'foo')).to eq('foo/2017-02-22_performance.txt')
			end
		end
	end
end
