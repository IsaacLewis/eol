require 'optiflag.rb'
require 'test/unit'

module HelpArgs extend OptiFlag::Flagset
  usage_flag "h","?","help"
  flag "dir"
end

class TC_HelpArgs < Test::Unit::TestCase

  def test_help_requested
    command_lines = 
           ["-dir thedire -?",
            "-dir thedire -h",
            "-dir thedire -help"]
    command_lines.each do |cl|
      argv = cl.split
      args = HelpArgs::parse(argv)
      assert(args.help_requested?,
             "A help flag was added to the command-line. Please register its existence.")
      assert_equal("thedire",args.flag_value.dir,
                   "thedire is the proper value of the dir flag")
    end
  end
  def test_no_help_requested
     command_lines = 
            ["-dir thedire",
             "-dir thedire -he",
             "-dir thedire -hElp"]
     command_lines.each do |cl|
      argv = cl.split
      args = HelpArgs::parse(argv)
      assert_equal("thedire",args.flag_value.dir,
                   "thedire is the proper value of the dir flag")

       assert(! args.help_requested?,
              "There are no help flags on the command line")
     end
 end
end
