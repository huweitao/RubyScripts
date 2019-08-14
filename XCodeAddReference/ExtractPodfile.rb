#!/usr/bin/ruby

$CurDir = Dir.getwd()

$LOAD_PATH.unshift($CurPath)

$PodInstallLogsPath = File.join($CurDir,'PodInatallLogs.bac')

def cache_podinstall_logs(projectPath)
    # run pod install and store logs
    Dir.chdir(projectPath)
    puts "Ruby run Pod install in #{Dir.pwd()}"
    puts "Ruby writes install logs in #{$PodInstallLogsPath}"
    system("pod install --verbose > #{$PodInstallLogsPath}")
end

def extract_pods_from_podinstall_logs()
    unless $PodInstallLogsPath
      puts "No Podfile in:"+projectPath
      exit
    end
    puts "Read from #{$PodInstallLogsPath}"
    startKey = "Downloading dependencies"
    endKey = "Generating Pods project"
    frameworks = []
    flag = false
    File.open($PodInstallLogsPath,"r").each_line do |line|
      # puts line
      if line.start_with?(startKey) then
        flag = true
        next
      end
      if line.start_with?(endKey) then
        flag = false
        break
      end
      filterLine = line.gsub(/[ ]/,'').gsub(/\n/,'')
      if flag and filterLine.length > 0 and filterLine.start_with?("->") then
        filterLine = filterLine.gsub(/->Using/,'').gsub(/\)/,'')
        podDep = filterLine.split("(")
        if podDep.length == 2 then
          info = {"name"=>podDep[0],"version"=>podDep[1]}
          frameworks.push(info)
        end
      end
    end
    puts "Pod dependecies ==>"
    puts frameworks
    return frameworks
end

def extract_cocoapods(projectPath)
    unless projectPath
      puts "No Podfile in:"+projectPath
      exit
    end
    podfile_path = projectPath + "/Podfile"
    puts "Pod install from ==> #{podfile_path}"
    cache_podinstall_logs(projectPath)
    extract_pods_from_podinstall_logs()
end

extract_cocoapods(ARGV[0])

# example:
# ruby ExtractPodfile.rb /Users/name/Desktop/CocoaPodHelper/Project
