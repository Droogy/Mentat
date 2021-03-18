#!/bin/bash

# Mentat by Droogy

# Mentat is a blue-team framework focused on modularity and portability
# First you'll need to run the baseline scan
# "check files" allows you to check the specified directory against your baseline
# and show anything that may have changed
# check login times and users with "check users"
# "honey port" sets up a bash honeypot with a fake banner we can customize

# version 1.0

# COLORS
green="\033[0;32m"
red="\033[0;31m"
nocolor="\033[0;0m"

# lets check if we have certain folders and then create them
# check if hashes folder does NOT exist
function infra {
	if [ ! -d "baseline/" ]
	then
		mkdir baseline
	else
		exit 1
	fi
	
	if [ ! -d "hashes/" ]
	then
		mkdir hashes
	else
		exit 1
	fi
}

# this will be our hash baseline, ideally we run this once?

function baseline_files {
	while read -r directory; do
		printf "${green}[*] Currently hashing: $directory\n\r${nocolor}"
		find "/$directory" -type f -exec md5sum "{}" + > baseline/"$directory".txt;
	done < dirs2watch.txt
}

function new_files {
	printf "${green}[*] Re-hashing and checking baseline for: $1\n\r${nocolor}"
	find "/$1" -type f -exec md5sum "{}" + > hashes/"$1".txt
	diff baseline/"$1".txt hashes/"$1".txt 1>/dev/null; ec=$?

	if [ $ec -eq 0 ]; then
		printf "${red}[*] No changes found in $1\n\r${nocolor}"
	else
		diff baseline/"$1".txt hashes/"$1".txt
	fi
}

function checker {
	printf "Which directory to check for mischief? \n\r"
	options=("/tmp" "/var" "/etc" "/bin" "/home" "/dev" "Quit")
	select opt in "${options[@]}"
	do
		case $opt in
			"/tmp")
				new_files tmp
				;;
			"/var")
				new_files var
				;;
			"/etc")
				new_files etc
				;;
			"/bin")
				new_files bin
				;;
			"/home")
				new_files home
				;;
			"/dev")
				new_files dev
				;;
			"Quit")
				break
				;;
			*)
				echo "Invalid Answer"
				;;
		esac
	done
}

# check who's logged in and return when they logged in
# print every user who's not the person currently running script
function snoopy {
	w -h | awk '{print $1 " logged in at: " $4}' | grep -v $USER
}	

function nullPit {
	i=1
	printf "${red}Starting up the null pit....${nocolor}\n\r"
	read -p "Which port do you wanna make the pit run on? [1000-65535]" port
	bdir="./.nullpit"
	banner="You found my backdoor \n\rtty1\r\n\rbackdoor login:"
	if [ ! -d "/root/.nullpit" ]; then
		mkdir ./.nullpit
		touch ./.nullpit/$port.txt
	fi
	while [ $i -lt 10 ];
		do	
		echo "~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~" >> $bdir/$port.log;
		echo -e $banner | nc -lnvp $port 1>> $bdir/$port.log 2>> $bdir/$port.log;
		echo "Connection attempt on: $port at" `date "+%r"`;
		echo >> $bdir/$port.log;
		echo "Attempted on:" `date "+%a %b %d %r"` >> $bdir/$port.log;
		echo "-------------------------------" >> $bdir/$port.log;
		i=$(($i+1))
	done
} 

# clean up the folders we made
function cleanup {
	printf "${red}Cleaning up hashes/ and baseline/...${nocolor}\n\r"
	rm -rf hashes/
	rm -rf baseline/
	rm -rf .nullpit/
}

function main_app {
	PS3="Please select your choice (or press enter): "
	options=("baseline" "check users" "check files" "cleanup" "honey port" "Quit")
	select opt in "${options[@]}"
	do
		case $opt in
			"baseline")
				infra;
				baseline_files;
				;;
			"check users")
				snoopy;
				;;
			"check files")
				checker;
				;;
			"cleanup")
				cleanup;
				;;
			"honey port")
				nullPit;
				;;
			"Quit")
				break;
				;;
			*)
				echo "Invalid Answer"
				;;
		esac
	done
}

main_app
