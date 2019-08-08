#!/usr/bin/ruby
# https://juejin.im/post/5a30fadc6fb9a0450909814c
# [sudo] gem install xcodeproj

ExtensionPath = 'XCodeAddReference'
CurPath = File.dirname(__FILE__)

require 'xcodeproj'

$LOAD_PATH.unshift(File.join(CurPath,ExtensionPath))

# handle ref

# add same refs(files) to multiply targets
def addXCodeMultiplyTargetsRef(filePath,targets,group)
	fileRef = createXCodeRef(filePath,group)
	targets.each do |target|
		addXCodeRef(fileRef,target)
	end
end

def createXCodeRef(filePath,group)
	unless filePath
      return
    end
    return group.new_reference(filePath)
end

def addXCodeRef(fileRef,target)
	unless fileRef
      return
    end

    if fileRef.to_s.end_with?("pbobjc.m", "pbobjc.mm") then
    	target.add_file_references([fileRef], '-fno-objc-arc')
    elsif fileRef.to_s.end_with?(".m", ".mm") then
    	target.source_build_phase.add_file_reference(fileRef, true)
    else
    	target.resources_build_phase.add_file_reference(fileRef, true)
    end
end

# def removeXCodeRef(target,fileRef)
# 	unless target
# 		return
# 	end
# 	puts "Remove Ref path:",fileRef.real_path
# 	if fileRef.real_path.to_s.end_with?(".m", ".mm") then
# 		target.source_build_phase.remove_file_reference(fileRef)
# 	else
# 		target.resources_build_phase.remove_file_reference(fileRef)
# 	end
# end

def copyFile(srcPath,dstPath)
	if dstPath == srcPath then
		return
	end
	# system("mkdir -p #{$srcDir}")
	puts "Copy from #{srcPath} to #{dstPath}"
	system("cp #{srcPath} #{dstPath}")
end

# main entrace
def addXCodeProjRefs(srcPath,dstDir,projectPath = '/targetName.xcodeproj',targetNames = [])

	puts "Targets:", targetNames

	# construct dstPath
	fileName = srcPath.split('/')[-1]
	dstPath = dstDir + "/" + fileName

	# copy file
	copyFile(srcPath,dstPath)

	# open Xcodeproj
	# project_path = File.join(projectDir, projectName)
	puts "Begin add files from" + srcPath + " to " + dstPath
	project = Xcodeproj::Project.open(projectPath)

	# prepare
	projDir = File.dirname(projectPath)
	projDir = projDir + '/'

	# relative path to main group, exp: /Users/name/Desktop/project/Settings/filename =>  Settings/filename
	groupSubpath = dstDir.gsub(projDir,"")
	puts "Destination Dir:",dstDir
	puts "Group subpath:",groupSubpath
	group = project.main_group.find_subpath(groupSubpath, true)
	group.set_source_tree('SOURCE_ROOT')

	puts "Group refs:"
	removeRefs = []
	group.files.each do |fileRef|
		puts fileRef.real_path.to_s
		if fileRef.real_path.to_s.end_with?(fileName) then
			# remove same ref
			removeRefs.push(fileRef)
		end
	end

	if removeRefs.count > 0 then
		puts "Need remove refs: ",removeRefs
	end

	# find target and add refs
	targetsFound = []
	
	project.targets.each do |target|
		if removeRefs.count > 0 then
			removeRefs.each do |ref|
				# remove exists ref
				# https://github.com/CocoaPods/Xcodeproj/blob/master/lib/xcodeproj/project/object/file_reference.rb
				ref.remove_from_project
			end
		end
		if targetNames.count == 0 then
			# no preferred targets
			targetsFound.push(target)
		else 
			if targetNames.include?(target.name.to_s) then 
				targetsFound.push(target)
			end
		end
	end

	# Batch add ref
	if targetsFound.length > 0
		addXCodeMultiplyTargetsRef(dstPath,targetsFound,group)
	end
	project.save
end

# params: srcPath = '/fileoutside/test.m',dstDir = '/fileinproject',projectPath = '/targetName.xcodeproj',targetNames = [target,targettest]
targets = []
ARGV.each.with_index do |param, index|
	if index >= 3 then
		targets.push(param)
	end
end
addXCodeProjRefs(ARGV[0],ARGV[1],ARGV[2],targets)


# Command Example 
# ruby \
# /Users/huweitao/Desktop/XCodeAddReference/XCodeAddRef.rb \
# /Users/huweitao/Desktop/Info.plist /Users/huweitao/Desktop/XCodeAddReference/DemoProject/Settings 
# /Users/huweitao/Desktop/XCodeAddReference/DemoProject/DemoProject.xcodeproj \
# DemoProject DemoProjectDev