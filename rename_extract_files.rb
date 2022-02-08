#!/usr/bin/env ruby
require 'FileUtils'
require 'date'
require 'Nokogiri'

#
#This Script will rename files according to the information specific date tags in the xml file. 
#The renamed file will be move to a different folder for processing
#
#
#

# Variables updated from command line parameters.
debugArg = false
debug = false
forceJob = false

configfile = 'c:File_containing_SFTP_info\.config'
lockfileArg = nil

def usage(s)
  $stderr.puts(s)
  $stderr.puts("Usage: #{File.basename($0)}: [-c <configfile>] [-L <lockfile>] [-d] [-f]")
  exit(2)
end

loop do
  case ARGV[0]
    when '-d' then
      ARGV.shift; debugArg = true
    when '-f' then
      ARGV.shift; forceJob = true
    when '-c' then
      ARGV.shift; configfile = ARGV.shift
	when '-k' then
      #ARGV.shift; configfile61 = ARGV.shift  
    #when '-L' then
      ARGV.shift; lockfileArg = ARGV.shift
    when /^-/ then
      usage("Unknown option: #{ARGV[0].inspect}")
    else
      break
  end
end

class JobLockFile
  def initialize(lockfilename)
    @lockfilename = lockfilename
  end

  def jobRunning
    # If the lock file exists, then just report its age and return true.
    if File.exists?(@lockfilename)
      mtime = File.mtime(@lockfilename)
      now = Time.new().tv_sec
      minsDelta = (now - mtime.tv_sec) / 60
      puts "Job already running since: #{mtime} [#{minsDelta} mins ago]"
      return true
    end
    # Else return false.
    return false
  end

  def startJob
    # Create the lockfile.
    File.open(@lockfilename, "w") do |lf|
      lf.write("lockfile")
    end
  end

  def endJob
    if File.exists?(@lockfilename)
      puts "Removing lock file."
      File.delete(@lockfilename)
    end
  end
end

# =========================================
# Default settings if not in config file...
lockfile = 'lockfile_during_running_to_prevent_override.lockfile'
hospitalId = 'xxxxxx'
renamedir = 'Path_of_rename_directory'
outdir = 'Path_of_directory_where_the_file_will_appear_after_rename'
errordir = '\error'
# =========================================

config = Hash[]
if File.exists?(configfile)
  File.open(configfile).each do |f|
    # Ignore comments in the config file.
    if /^\s*#/ =~ f
      next
    end
    parts = f.split(/[=\r\n]/)
    config[parts[0]] = parts[1]
  end
  if config['rename_extract_lockfile'] != nil
    lockfile = config['rename_extract_lockfile']
  end
  if config['hospitalId'] != nil
    hospitalId = config['hospitalId']
  end
  if config['renamedir'] != nil
    renamedir = config['renamedir']
  end
  if config['outdir'] != nil
    outdir = config['outdir']
  end
  if config['errordir'] != nil
    errordir = config['errordir']
  end
  if config['debug'] != nil
    debug = (config['debug'] == 'true')
  end
else
  puts "The config file #{configfile} does not exist."
end
# Debug true if set on command line.
if debugArg
  debug = true
end
class Logger
  def initialize(debug)
    @debug = debug
  end

  def debug(msg)
    if @debug
      puts msg
    end
  end

  def debug?()
    return @debug
  end

  def info(msg)
    puts msg
  end
end
logger = Logger.new(debug)

if logger.debug?()
  logger.debug('Config: ')
  config.keys.each { |k| logger.debug("  " + k + ': ' + config[k]) }
end

# Override lockfile default and lockfile from config with arg.
if lockfileArg != nil
  lockfile = lockfileArg
end

# Create the lock file object.
jobLockFile = JobLockFile.new(lockfile)

# Set up lock file signal handler...
trap("SIGINT") do
  jobLockFile.endJob
  exit
end

# Clean the lock file if forcing the job.
if forceJob
  jobLockFile.endJob
end

# Exit if the job is already running.
if jobLockFile.jobRunning
  exit
end

# Create the lock file.
jobLockFile.startJob

class FileHelper
  def initialize(debug)
    @minAgeInMins = 0
    @logger = Logger.new(debug)
  end

  def readyForProcessing(filename)
    # Make sure the file meets the last modified requirement...
    now = Time.new().tv_sec
    mtime = Time.new().tv_sec - (5 * 60)
    ftime = File.mtime(filename).tv_sec
    minsOld = (now - ftime) / 60
    @logger.debug "Now: #{now}, ftime: #{ftime}, minsOld: #{minsOld}, minAgeInMins: #{@minAgeInMins}"
    if minsOld >= @minAgeInMins
      begin
        filename2 = filename + '.tmpmv'
        FileUtils.mv(filename, filename2)
        FileUtils.mv(filename2, filename)
      rescue Exception => emv
        @logger.debug "File is busy, not ready to process."
        return false
      end
      @logger.info "Old enough to process at #{minsOld} minutes old."
      return true
    end
    @logger.info "Not old enough. It must be unchanged for an additional #{@minAgeInMins - minsOld} minutes."
    return false
  end
end

fileHelper = FileHelper.new(debug)

logger.info "Starting at #{Time.new()}"

filesep = "/" #FIXME change this back

infiles = Dir.entries(renamedir)

def getDateRangeFromExtract(parsedMergeData, dateTagName)
  numpats = parsedMergeData.xpath('count(parent/child)').to_i
  earliestDate = latestDate = parsedMergeData.xpath("parent/child[1]/" + dateTagName).inner_text

  for i in 2..numpats
    date = parsedMergeData.xpath("parent/child[#{i}]/" + dateTagName).inner_text
    if date > latestDate then
      latestDate = date
    end
    if date < earliestDate then
      earliestDate = date
    end
  end
  return earliestDate, latestDate
end



def getDateRangeFromExtract60(parsedMergeData, dateTagNameB, dateTagNameE)
 
 
  numpats = parsedMergeData.xpath("count(parent/#{dateTagNameB})").to_i
 puts "numpats: #{numpats}"
  earliestDatetrim = parsedMergeData.xpath("parent/#{dateTagNameB}").inner_text
  earliestDate = earliestDatetrim.gsub(/[[:space:]]/, '')  
puts "earliestDate: #{earliestDate}" 
  latestDatetrim = parsedMergeData.xpath("parent/#{dateTagNameE}").inner_text
  latestDate = latestDatetrim.gsub(/[[:space:]]/, '')
  if earliestDate == "" then
    return nil,nil
  end
  for i in 2..numpats
    date = parsedMergeData.xpath("parent/#{dateTagNameB}[#{i}]/" + dateTagName).inner_text
    if date > latestDate then
      latestDate = date
    end
    if date < earliestDate then
      earliestDate = date
    end
  end
  return earliestDate, latestDate
end

def getDateRangeFromMTAuditLog(auditLogFilename)
  auditLogFile = File.open(auditLogFilename, "r")
  earliestDate = latestDate = auditLogFile.readline.split('|')[3]

  auditLogFile.each_line do |line|
    date = line.split('|')[3]
    if date > latestDate then
      latestDate = date
    end
    if date < earliestDate then
      earliestDate = date
    end
  end
  auditLogFile.close
  return earliestDate, latestDate
end

# Process each file in the outdir...
for infile in infiles
  filename = renamedir + filesep + infile

  # Capture array of statuses for each step of the merge/checksum/zip/ftp/archive process.
  statusLog = []

  # begin exception handling block...
  begin
    fileType = nil
    earliestAbsDate = latestAbsDate = earliestDisDate = latestDisDate = nil

    if /#{hospitalId}_file_A-?.*\.xml$/ =~ filename
      fileType = 'abs'
    elsif /#{hospitalId}_file_B-?.*\.xml$/ =~ filename
      fileType = 'dis'
    elsif /#{hospitalId}_file_C-?.*\.xml$/ =~ filename
      fileType = 'inbed'
    elsif /#{hospitalId}_auditLog-?.*\.txt$/ =~ filename
      fileType = 'mtaudit'
    else
      # Ignore all other file types.
      next
    end
    logger.info('========================================')
    logger.info('Processing file ' + filename)
    logger.debug('File is type ' + fileType)
    # Make sure the file is unchanged
    if not fileHelper.readyForProcessing(filename)
      next
    end
    if fileType == 'abs'|| fileType == 'dis'
      # Parse the XML in the file to make sure it is valid and so we can find out what dates it covers

      mergeData = "<parent>\n"

      File.foreach(filename) do |line|
        line.encode('UTF-8', :invalid => :replace, :undef => :replace)  
        mergeData << line

      end

      parsedMergeData = Nokogiri::XML(mergeData)
      if fileType == 'abs'
        earliestAbsDate, latestAbsDate = getDateRangeFromExtract60(parsedMergeData, "date.b", "date.e")
      elsif fileType == 'dis'
        earliestDisDate, latestDisDate = getDateRangeFromExtract(parsedMergeData, "dis.date")
      end

      if !earliestAbsDate && !earliestDisDate
        # No date range was present, rename file to a name that will never be processed.
        mtime = File.mtime(filename)
        date = Date.parse(mtime.to_s)
        # Rename to prior day, which will cover the automated extract case.
        dayStr = (date - 1).strftime('%Y%m%d')
        ofile = infile.sub(/\.xml$/, '_' + dayStr + '_nodaterange.xml')
        errorfile = errordir + filesep + ofile
        FileUtils.mv(filename, errorfile)
        logger.info("No date present in file: Moved #{filename} to #{outfile}.")
        next
      end
    end
    if fileType == 'abs'
      ofile = "#{hospitalId}_file_A_#{earliestAbsDate}_#{latestAbsDate}.xml"
    elsif fileType == 'dis'
      ofile = "#{hospitalId}_file_B_#{earliestDisDate}_#{latestDisDate}.xml"
    elsif fileType == 'inbed'
      mtimeStr = File.mtime(filename).strftime('%Y%m%d_%H%M')
      # note that the output filename needs to match what process_files is looking for
      ofile = "#{mtimeStr}_#{hospitalId}_file_C.xml"
    elsif fileType == 'mtaudit'
      earliestMTAuditDate, latestMTAuditDate = getDateRangeFromMTAuditLog(filename)
      ofile = "#{hospitalId}_vendor_meditech_auditLog_#{earliestMTAuditDate}_#{latestMTAuditDate}.txt"
    end
    outfile = outdir + filesep + ofile
    FileUtils.mv(filename, outfile)
    logger.info("Moved #{filename} to #{outfile}.")

  rescue
    logger.info('Error processing ' + filename)
    logger.info("Error: #{$!}")
    statusLog << "ERROR: #{$!}"

    # Create log file from statusLog array.
    logfilename = filename + '.errorlog'
    File.open(logfilename, "w") do |log|
      statusLog.each do |msg|
        log.puts(msg)
      end
    end
  end

  logger.info "Finished processing #{filename}."
end

# End the job.
jobLockFile.endJob
