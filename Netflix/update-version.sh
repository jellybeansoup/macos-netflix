#!/bin/bash
# Link: <https://gist.github.com/jellybeansoup/db7b24fb4c7ed44030f4>
#
# A command-line script for incrementing build numbers for all known targets in an Xcode project.
#
# This script has two main goals: firstly, to ensure that all the targets in a project have the
# same CFBundleVersion and CFBundleShortVersionString values. This is because mismatched values
# can cause a warning when submitting to the App Store. Secondly, to ensure that the build number
# is incremented appropriately when git has changes.
#
# If not using git, you are a braver soul than I.

##
# The xcodeproj. This is usually found by the script, but you may need to specify its location
# if it's not in the same folder as the script is called from (the project root if called as a
# build phase run script).
#
# This value can also be provided (or overridden) using "--xcodeproj=<path>"
#
#xcodeproj="Project.xcodeproj"

##
# We have to define an Info.plist as the source of truth. This is typically the one for the main
# target. If not set, the script will try to guess the correct file from the list it gathers from
# the xcodeproj file, but this can be overriden by setting the path here.
#
# This value can also be provided (or overridden) using "--plist=<path>"
#
#plist="Project/Info.plist"

##
# By default, the script ensures that the build number is incremented when changes are declared
# based on git's records. Alternatively the number of commits on the current branch can be used
# by toggling the "reflect_commits" variable to true. If not on "master", the current branch name
# will be used to ensure no version collisions across branches, i.e. "497-develop".
#
# This setting can also be enabled using "--reflect-commits"
#
#reflect_commits=true

##
# If you would like to iterate the build number only when a specific branch is checked out
# (i.e. "master"), you can specify the branch name. The current version will still be replicated
# across all Info.plist files (to ensure consistency) if they don't match the source of truth.
#
# This setting can be enabled for multiple branches can be enabled by using comma separated names
# (i.e. "master,develop"). No spacing is permitted.
#
# This setting can also be enabled using "--branch"
#
#enable_for_branch="master"

##
# Released under the BSD License
#
# Copyright © 2017 Daniel Farrelly
# 
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
# 
# *	Redistributions of source code must retain the above copyright notice, this list
# 	of conditions and the following disclaimer.
# *	Redistributions in binary form must reproduce the above copyright notice, this
# 	list of conditions and the following disclaimer in the documentation and/or
# 	other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# We use PlistBuddy to handle the Info.plist values. Here we define where it lives.
plistBuddy="/usr/libexec/PlistBuddy"

# Parse input variables and update settings.
for i in "$@"; do
case $i in
	-h|--help)
	echo "usage: sh version-update.sh [options...]\n"
	echo "Options: (when provided via the CLI, these will override options set within the script itself)"
	echo "-b, --branch=<name[,name...]> Only allow the script to run on the branch with the given name(s)."
	echo "    --build=<number>          Apply the given value to the build number (CFBundleVersion) for the project."
	echo "-i, --ignore-changes          Ignore git status when iterating build number (doesn't apply to manual values or --reflect-commits)."
	echo "-p, --plist=<path>            Use the specified plist file as the source of truth for version details."
	echo "    --reflect-commits         Reflect the number of commits in the current branch when preparing build numbers."
	echo "    --version=<number>        Apply the given value to the marketing version (CFBundleShortVersionString) for the project."
	echo "-x, --xcodeproj=<path>        Use the specified Xcode project file to gather plist names."
	echo "\nFor more detailed information on the use of these variables, see the script source."
	exit 1 
	;;
	--reflect-commits)
	reflect_commits=true
	shift
	;;
	-x=*|--xcodeproj=*)
	xcodeproj="${i#*=}"
	shift
	;;
	-p=*|--plist=*)
	plist="${i#*=}"
	shift
	;;
	-b=*|--branch=*)
	enable_for_branch="${i#*=}"
	shift
	;;
	--build=*)
	specified_build="${i#*=}"
	shift
	;;
	--version=*)
	specified_version="${i#*=}"
	shift
	;;
	-i|--ignore-changes)
	ignore_git_status=true
	shift
	;;
	*)
	;;
esac
done

# Locate the xcodeproj.
# If we've specified a xcodeproj above, we'll simply use that instead.
if [[ -z ${xcodeproj} ]]; then
	xcodeproj=$(find . -depth 1 -name "*.xcodeproj" | sed -e 's/^\.\///g')
fi

# Check that the xcodeproj file we've located is valid, and warn if it isn't.
# This could also indicate an issue with the code used to automatically locate the xcodeproj file.
# If you're encountering this and the file exists, ensure that ${xcodeproj} contains the correct
# path, or use the "--xcodeproj" variable to provide an accurate location.
if [[ ! -f "${xcodeproj}/project.pbxproj" ]]; then
	echo "${BASH_SOURCE}:${LINENO}: error: Could not locate the xcodeproj file \"${xcodeproj}\"."
	exit 1
else 
	echo "Xcode Project: \"${xcodeproj}\""
fi

# Find unique references to Info.plist files in the project
projectFile="${xcodeproj}/project.pbxproj"
plists=$(grep "^\s*INFOPLIST_FILE.*$" "${projectFile}" | sed -Ee 's/^[[:space:]]+INFOPLIST_FILE[[:space:]*=[[:space:]]*["]?([^"]+)["]?;$/\1/g' | sort | uniq)

# Attempt to guess the plist based on the list we have.
# If we've specified a plist above, we'll simply use that instead.
if [[ -z ${plist} ]]; then
	read -r plist <<< "${plists}"
fi

# Check that the plist file we've located is valid, and warn if it isn't.
# This could also indicate an issue with the code used to match plist files in the xcodeproj file.
# If you're encountering this and the file exists, ensure that ${plists} contains _ONLY_ filenames.
if [[ ! -f ${plist} ]]; then
	echo "${BASH_SOURCE}:${LINENO}: error: Could not locate the plist file \"${plist}\"."
	exit 1		
else
	echo "Source Info.plist: \"${plist}\""
fi

# Find the current build number in the main Info.plist
mainBundleVersion=$("${plistBuddy}" -c "Print CFBundleVersion" "${plist}")
mainBundleShortVersionString=$("${plistBuddy}" -c "Print CFBundleShortVersionString" "${plist}")
echo "Current project version is ${mainBundleShortVersionString} (${mainBundleVersion})."

# If the user specified a marketing version (via "--version"), we overwrite the version from the source of truth.
if [[ ! -z ${specified_version} ]]; then
	mainBundleShortVersionString=${specified_version}
	echo "Applying specified marketing version (${specified_version})..."
fi

# Increment the build number if git says things have changed. Note that we also check the main
# Info.plist file, and if it has already been modified, we don't increment the build number.
# Alternatively, if the script has been called using "--reflect-commits", we just update to the
# current number of commits. We can also specify a build number to use with "--build".
git=$(sh /etc/profile; which git)
branchName=$("${git}" rev-parse --abbrev-ref HEAD)
if [[ -z ${enable_for_branch} ]] || [[ ",${enable_for_branch}," == *",${branchName},"* ]]; then
	if [[ ! -z ${specified_build} ]]; then
		mainBundleVersion=${specified_build}
		echo "Applying specified build number (${specified_build})..."
	elif [[ ! -z ${reflect_commits} ]] && [[ ${reflect_commits} ]]; then
		currentBundleVersion=${mainBundleVersion}
		mainBundleVersion=$("${git}" rev-list --count HEAD)
		if [[ ${branchName} != "master" ]]; then
			mainBundleVersion="${mainBundleVersion}-${branchName}"
		fi
		if [[ ${currentBundleVersion} != ${mainBundleVersion} ]]; then
			echo "Branch \"${branchName}\" has ${mainBundleVersion} commit(s). Updating build number..."
		else
			echo "Branch \"${branchName}\" has ${mainBundleVersion} commit(s). Version is stable."
		fi
	elif [[ ! -z ${ignore_git_status} ]] && [[ ${ignore_git_status} ]]; then
		echo "Iterating build number (forced)..."
		mainBundleVersion=$((${mainBundleVersion} + 1))
	else
		status=$("${git}" status --porcelain)
		if [[ ${#status} == 0 ]]; then
			echo "Repository does not have any changes. Version is stable."
		elif [[ ${status} == *"M ${plist}"* ]] || [[ ${status} == *"M \"${plist}\""* ]]; then
			echo "The source Info.plist has been modified. Version is assumed to be stable. Use --ignore-changes to override."
		else		
			echo "Repository is dirty. Iterating build number..."
			mainBundleVersion=$((${mainBundleVersion} + 1))
		fi
	fi
else
	echo "${xcodeproj}:0: warning: Version number updates are disabled for the current git branch (${branchName})."
fi

# Update all of the Info.plist files we discovered
while read -r thisPlist; do
	# Find out the current version
	thisBundleVersion=$("${plistBuddy}" -c "Print CFBundleVersion" "${thisPlist}")
	thisBundleShortVersionString=$("${plistBuddy}" -c "Print CFBundleShortVersionString" "${thisPlist}")
	# Update the CFBundleVersion if needed
	if [[ ${thisBundleVersion} != ${mainBundleVersion} ]]; then
		echo "Updating \"${thisPlist}\" with build ${mainBundleVersion}..."
		"${plistBuddy}" -c "Set :CFBundleVersion ${mainBundleVersion}" "${thisPlist}"
	fi
	# Update the CFBundleShortVersionString if needed
	if [[ ${thisBundleShortVersionString} != ${mainBundleShortVersionString} ]]; then
		echo "Updating \"${thisPlist}\" with marketing version ${mainBundleShortVersionString}..."
		"${plistBuddy}" -c "Set :CFBundleShortVersionString ${mainBundleShortVersionString}" "${thisPlist}"
	fi
done <<< "${plists}"
