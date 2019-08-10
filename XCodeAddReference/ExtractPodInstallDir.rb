#!/usr/bin/ruby

$CurPath = File.dirname(__FILE__)

$LOAD_PATH.unshift($CurPath)

$PodInstallLogsPath = File.join($CurPath,'PodInatallLogs')

def cache_podinstall_logs(projectPath)
	# run pod install and store logs
    Dir.chdir(projectPath)
    puts "Ruby run Pod install..."
    system("pwd")
    system("pod install --verbose > #{$PodInstallLogsPath}")
end

# tips: make sure that you can use xcode to build workspace with no errors!
def get_workspacebuild_dir(appname,config,projectPath)
	# config='Release'
    # appname='GCash'
    system("cd #{projectPath}")
    system("pwd")
    grepkey = 'GenerateDSYMFile '
    # 'export PODS_BUILD_DIR='
    puts "======> Clean Workspace"
    # xcodebuild clean -workspace HSwiftTools.xcworkspace -scheme HSwiftTools -configuration Release
	system("xcodebuild clean  -workspace \"#{projectPath}/#{appname}.xcworkspace\" -scheme \"#{appname}\" -configuration \"#{config}\"")

	puts "======> Build For Device"
	# xcodebuild -showBuildTimingSummary -workspace HSwiftTools.xcworkspace -scheme HSwiftTools -configuration Release -sdk iphoneos build
	system("xcodebuild -showBuildTimingSummary -workspace \"#{projectPath}/#{appname}.xcworkspace\" -scheme \"#{appname}\" -configuration \"#{config}\" -sdk iphoneos build")

	puts "======> Build For Simulator"
	# xcodebuild -showBuildTimingSummary -workspace HSwiftTools.xcworkspace -scheme HSwiftTools -configuration Release -sdk iphonesimulator build
	system("xcodebuild -showBuildTimingSummary -workspace \"#{projectPath}/#{appname}.xcworkspace\" -scheme \"#{appname}\" -configuration \"#{config}\" -sdk iphonesimulator build 2>&1 | tee #{$CurPath}/xcode_build.log")
    
    pods_build_dir=`grep \"#{grepkey}\" -m 1  #{$CurPath}/xcode_build.log | grep -o '[^$(printf '\\t') ].*'`
    pods_build_dir.slice!(grepkey)
    puts "======> Complete Build!"
    splitKey = "/Products"
    if pods_build_dir.include?(splitKey) then
    	pods_build_dir = pods_build_dir.split(splitKey)[0]
    	pods_build_dir = pods_build_dir + splitKey
    end
    puts "======> Pod Build dir : ",pods_build_dir
    return pods_build_dir
end

get_workspacebuild_dir(ARGV[0],ARGV[1],ARGV[2])

# example:
# ruby ExtractPodInstallDir.rb HSwiftTools Release /Users/name/Desktop/CocoaPodHelper/HSwiftTools
