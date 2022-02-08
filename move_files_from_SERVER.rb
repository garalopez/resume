require 'fileutils'
require 'net/ssh'
require 'net/scp'

Net::SSH.start("server", "root", :password => "password") do |ssh|

ssh.scp.download!('Path_From_Server/.', 'Local_path', :recursive => true) 

filelist = ssh.exec! ("cd to_server_path_to_list_files && ls -l")
  puts filelist

delete = ssh.exec! ("rm remove_files_from_server_after_move/*.xml")
puts delete

end

