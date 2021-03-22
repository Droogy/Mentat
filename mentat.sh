#!/bin/bash

# Mentat by Droogy

# Mentat is a blue-team framework focused on modularity and portability
# First you'll need to run the baseline scan
# "check files" allows you to check the specified directory against your baseline
# and show anything that may have changed
# check login times and users with "check users"
# "honey port" sets up a bash honeypot with a fake banner we can customize

# version 1.1

#!/bin/bash

# COLORS

cyan="\033[0;36m"
green="\033[0;32m"
red="\033[0;31m"
nocolor="\033[0;0m"

ColorCyan(){
	echo -ne $cyan$1$nocolor
}
ColorGreen(){
	echo -ne $green$1$nocolor
}
ColorRed(){
	echo -ne $red$1$nocolor
}
# lets check if we have certain folders and then create them
function infra {
	# check if hashes folder does NOT exist
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
	clear
	printf "${green}[*] Re-hashing and checking baseline for: $1\n\r${nocolor}"
	sleep .5
	find "/$1" -type f -exec md5sum "{}" + > hashes/"$1".txt
	diff baseline/"$1".txt hashes/"$1".txt 1>/dev/null; ec=$?

	if [ $ec -eq 0 ]; then
		printf "${red}[*] No changes found in $1\n\r${nocolor}"
	else
		diff baseline/"$1".txt hashes/"$1".txt
	fi
	sleep 3
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
	if [ ! -d "./.nullpit" ]; then
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

# watch for all outgoing connections
# by monitoring the SYN bit set which is tcp[13] == 2
# we can make the tcpdump buffered with -l to grep stdout as well
function outWatch {
	ip=`ifconfig | grep broadcast | tr -s ' ' | cut -d ' ' -f 3`
	tcpdump -l -i any src host $ip and tcp[13]==2 | \
		awk '{print "A user tried connecting to: "$5}'
}

# let's make it loud and annoying to login
# we'll just echo some stuff into users' .profile files
function loudLogin {
	find /home -type f -name ".profile" -exec \
		echo -ne "wall 'hey everyone $USER just logged in!' 
		while [1]; do
			sleep 10
			Connection lost...attempting to reconnect
		done &" >> {} \;
}	
		
function main_app_v2 {
echo -ne "
$(ColorCyan 'Mentat:')
$(ColorGreen '1)') Take baseline *Do this first*
$(ColorGreen '2)') Check for user logins
$(ColorGreen '3)') Check files for change
$(ColorGreen '4)') Cleanup Files
$(ColorGreen '5)') Make logins loud for users
$(ColorGreen '6)') Create a honeypot
$(ColorGreen '7)') Watch for outgoing connections
$(ColorGreen '8)') $(ColorRed 'Quit')
$(ColorGreen 'Choose:')"
		read a
		case $a in
			1) infra && baseline_files ; main_app_v2 ;;
			2) snoopy; main_app_v2 ;;
			3) new_files tmp; new_files var; new_files home; new_files root; \
				new_files bin; main_app_v2 ;;
			4) cleanup; main_app_v2 ;;
			5) loudLogin; main_app_v2 ;;
			6) nullPit; main_app_v2 ;;
			7) outWatch; main_app_v2 ;;
			8) exit 0;;
			*) echo "Invalid Answer" ; main_app_v2 ;;
		esac
}

main_app_v2
