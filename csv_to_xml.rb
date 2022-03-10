#!/usr/bin/ruby

require 'FileUtils'
require 'zlib'
require 'csv'
require 'date'

#Setting variables

#Setting up vendor name variable
vendor = 'Cerner'
#Setting up DH or KY or ULH
loc= 'DH'
#date created to included yesterday's date on the out file
date = "#{(Date.today-1).strftime("%Y%m%d")}"
#UID of client
UID = '00000'
#outfile containing the file name after converting from csv to xml 
outfile = "INT_#{loc}_#{vendor}_Denom_#{date}_#{date}.xml"
outdir  = 'e:\IHM\manual'
#indir containing the directory where the file is located before changing to xml 
indir   = 'e:\IHM\manual'

#print "CSV file to read: "
#Removed since the script can be use 
#input_file = "#{indir}\\#{infile}"

print "File to write XML to: "
output_file = "#{outdir}\\#{outfile}"
#output_file = "#{outdir}"

files = Dir.entries(indir)
puts files
for input_file in files
	if /(INT_#{loc}_#{vendor}_Denom_[0-9]{8}_[0-9]{8}.txt)$/ =~ input_file

print "What to call each record: "
global_name = 'cerner'
record_name = 'cerner_patient'

encoding = "?xml version='1.0' encoding='iso-8859-1'?"
	
csv = CSV::parse(File.open("#{indir}\\#{input_file}") {|f| f.read} )
fields = csv.shift
puts "Writing XML..."

File.open(output_file, 'w') do |f|

  f.puts "<#{encoding}>"

  f.puts "<#{global_name}>"

  csv.each do |record|
    f.puts "<#{record_name}>"

    for i in 0..(fields.length - 1)

      f.puts "<#{fields[i]}>#{record[i]}</#{fields[i]}>"

    end

    f.puts "</#{record_name}>"

  end

  f.puts "</#{global_name}>"

 
end # End file block - close file

puts "Contents of #{input_file} written as XML to #{output_file}."

	end

end