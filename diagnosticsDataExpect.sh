#!/bin/bash

#Arman Kapbasov
#Parts adapted from www.stackoverflow.com

#================USAGE============
#To run..
#        ./diagnosicsData.sh [IP/Hostname]

#add -h for HELP menu

#Default output..
#        [hostname]_[date]_opsDiag.tar.gz

#You can change port by adding 2nd command line argument (optional)..
#        ./diagnosicsData.sh [IP/Hostname] [port]

#extract tar/output file with: tar -zxvf [filename]
#=================================
#==========Flags==========
#HELP Function

timedate=$(date +"%Y.%m.%d-%H.%M")
#max line size
size=1000
timeFactor=1
promptS="# $"
promptM=">$"
IP=${1}
port=""
cfilename=$IP"_"$timedate"_opsDiag.tar.gz"

commands=(
	'cat /etc/os-release'
	'iostat -tc'
	'cat /var/local/openvswitch/config.db'
	'ps -aux'
	'systemctl list-unit-files --all --state=failed'
	'netstat -an'
   )

nameA=(
	"$timedate.version"
	"$timedate.iostat"
	"$timedate.startup.config"
	"$timedate.process"
	"$timedate.failed.service.units"
	"$timedate.netstat"
)
#'dmesg'
#'ovsdb-client dump'

#"$timedate.kernel.message.buffer"
#"$timedate.running.config"

#folders=(
#	"/var/log/*"
#	"/var/lib/systemd/coredump/*"
#)
#folderA=(
#	"$timedate.logs"
#	"$timedate.cores"
#)


function HELP {
  echo -e \\n"To run:"\\n"     ./diagnosicsData.sh [IP/Hostname] [port *optional]"\\n
  echo -e "Add port number:
     ./diagnosicsData.sh [IP/Hostname] [port]"\\n
  echo -e "Prompt HELP menu:
     ./diagnosicsData.sh -h"\\n
  echo -e "Extract tar/output file with:
     tar -zxvf [filename]"\\n
  exit 1
}

wc(){
	cmd1=$2
        #localCount2=$2
        localName=$1
	cmd=""
		
	#for (( i=0; i<$localCount1; i++ ));
	#do
		cmd+="expect \"$promptS\""$'\n'
		cmd+="send -- \"$cmd1> $localName\\r\""$'\n'
	#done

	#for (( i=0; i<$localCount2; i++ ));
        #do
        #        cmd+="expect \"$promptS\""$'\n'
        #        cmd+="send -- \"mkdir ${folderA[$i]} && cp -r ${folders[$i]} ${folderA[$i]} \\r\""$'\n'
        #done


        /usr/bin/expect << EOD
        log_user 0

        set timeout -1
        spawn ssh InReach@$IP
        set PID "process id : [pid]"
        expect "InReach@$IP's password: " {send "access\r"}
       
	proc logout args {
		expect "Password: "
		send "system\r"

		expect "$promptM"
        	send "logout port async $port\r"
       
		expect "$promptM"
                send "connect port async $port\r"
	 }

        expect ">$"
        send "connect port async $port\r"
        send "\r"

        expect  {
                        ">$" {send "enable\r"
                        logout
			send "\r"
			exp_continue
			}
                        "login: " { send "root\r"
                        exp_continue}
                        "# $" {send "\r"}
        }

	$cmd

	expect "$promptS" {send "\r"}

	expect "$promptS" { send "wc -c < $localName\r" }
	expect "$promptS" {send "\r"}
        puts [open $localName.wc w] \$expect_out(buffer)
	expect "$promptS" {send "\r"}

EOD
}

multiple1(){
        localTotal=$1
        localSize=$2
        localName=$3
	localCounter=0
	localS=0
	localL=-1
	#localOffset=$(($localSize+1))

        /usr/bin/expect << EOD
       	log_user 0

        set timeout -1

	
        spawn ssh InReach@$IP

        expect "InReach@$IP's password: " {send "access\r"}
        expect  {
                        "$promptM" { send "enable\r"
                        exp_continue }

                        "Password: " { send "system\r"}
        }
        expect "$promptM"
        send "logout port async $port\r"

        expect "$promptM"
        send "connect port async $port\r"
        send "\r"

	expect "$promptS" { send "cat $localName > $localName.copy\r" };
	expect "# $" {send "\n\r"};
	expect "# $" {send "\n\r"};

		
	
	set c 0
	set iL 0
	while {\$iL <= $localTotal} {
	 	set iL [ expr \$iL+$localSize ]
	
		expect -re "# $" { send "head -c $localSize $localName && echo '' \r" };
		expect "# $" {send "\r"};
		set file [open $localName.\$c w];
                puts \$file \$expect_out(buffer);
                close \$file
		expect "# $" {send "clear\r"};
		expect "# $" {send "clear\r"};
		expect "# $" {send "clear\r"};
		expect "# $" {send "clear\r"};

		expect "# $" { send "tail -c +$localOffset $localName > $localName.temp\r" };
		expect "# $" { send "cat $localName.temp> $localName\r" };
		expect "# $" { send "rm $localName.temp\r" };

        	expect "# $" {send "clear\r"};
		expect "# $" {send "clear\r"};
		expect "# $" {send "clear\r"};
		expect "# $" {send "clear\r"};
		
		set c [expr \$c+1];
	}
	expect "# $" {send "rm $localName\r"}
	expect "# $" {send "rm $localName.copy\r"}
	expect "# $" {send "\r"}

EOD
}

statusBar() {
	value=$1
	max=$2
	title=$3
	width=30
    	
	perc=$(( value * 100 / max ))
    	num=$(( value * width / max ))
   	bar=
    	if [ $num -gt 0 ]; then
        	bar=$(printf "%0.s=" $(seq 1 $num))
    	fi
    	
	line=$(printf "%s [%-${width}s] (%d%%)" ">>$title" "$bar" "$perc")
    	echo -en "${line}\r"
}
waitC(){
	file=$1
	while :
	do
		if [ -f $file ] ; then
			return
		fi
		sleep $timeFactor
	done
}

loop(){
	tcount=0
	count1=${#commands[@]}
	count2=${#nameA[@]}
	while :
	do
		flag=0
		cmd_raw=${commands[$tcount]}
		cmdname=${nameA[$tcount]}
		filename=$cmdname
		wc $filename "$cmd_raw" &
		echo -e "\n>>Creating compressed file: $filename"
		while : 
		do
			if [  -f $filename.wc ] ; then
				echo ">>$filename created.."
				tr -d $'\r' < $filename.wc  > $filename.wc.temp
				totalChar="$(sed '2q;d' < $filename.wc.temp)"
				rm $filename.wc.temp	
				fileCount=0
				charCount=0
				multiple1 $totalChar $size $filename &
				echo -e ">>File char size: $totalChar"
				statusBar $charCount $totalChar "Copying $filename"
				while  :  
				do	
					charCount=$(($charCount+$size))
					if [ $charCount -ge $totalChar ]  ; then
						charCount=$totalChar
						waitC "$filename.$fileCount"
						statusBar $charCount $totalChar "Copying $filename"
						rm $filename.wc
						flag=1
						break
					fi
					waitC "$filename.$fileCount"
					statusBar $charCount $totalChar "Copying $filename"
					fileCount=$(($fileCount+1))
				done
			fi
		sleep $timeFactor
		if [ $flag -eq 1 ]; then
			break
		fi
		done

				for f in $filename*
        			do
                			tr -d $'\r' < $f  > $f"temp"
                			rm $f
                			sed -i '$ d' $f"temp"
                			sed 1d $f"temp" > $f
                			rm $f"temp"
        			done
				head -c -1 -q  $(ls -v $filename*) > temp.txt
				rm $filename*
				cat temp.txt > $filename
				rm temp.txt
				echo -e "\n>>$filename succesfully copied!" 
				tcount=$((tcount+1))
				if [ $tcount -eq $count2 ] ; then
					break
				fi
		done
}

match(){
	mkdir $3
	cat $1| while read line
	do
		sed -e '/patternNewFile/,$d'<$2>$line #copy the beggining of file
		sed -e '1,/patternNewFile/d' < $2> temp #copy the rest of file
		cat temp > $2
		mv $line $3
	done
	rm temp
}

#tar and remove intermediate files
compress(){
	filename=$1
	echo "Target tar file <"$cfilename">"
	echo "[Compressing]..."
	export GZIP=-9
	tar -zcvf $cfilename $timedate*
	rm -r "$filename"*
	echo -e "...[done!]"\\n
	exit 1
}


while getopts "hod:f:" opt; do
        case $opt in
        h)
                HELP
            exit 1
        ;;
        \?)
                echo -e \\n"Unrecognized option -$OPTARG"
                HELP
                exit 1
        ;;
        esac
done


#check for command line arguments
if [ $# -eq 0 ]; then
    echo -e \\n"Error:Invalid script call, opening [HELP MENU].."
    HELP
    exit 1
fi


if [ "$2" != "" ]; then 	
	let port=${2}
	filename=$timedate
	(echo ">>Connecting to $IP on port $port"; loop)
	
	compress $filename
	exit 1
fi

#else direct IP connection
#check IP address
#report error if no ssh connection
var=`nmap $IP -PN -p $port ssh | grep open`
ok="22/tcp open ssh"
if [[ $(echo $var) == $ok ]] ; then
  echo -e \\n$IP "[online], ready.."
else
  echo -e \\n"Error:" Host $IP "[cannot connect].."\\n
  exit 1
fi

#=====poll data to tar=======

#fix knownhosts issue, not host key checking
c="-o StrictHostKeyChecking=no -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null"

#Version
if $(scp $c root@$1:/etc/os-release $timedate.version >&/dev/null);
        then echo ">>Copied: version" ;
        else echo "--Failed: retrieve version"
fi
#processes
if $(ssh $c root@$1 "ps -aux" >$timedate.processes >&/dev/null );
        then $(ssh $c root@$1 "ps -aux" >$timedate.processes)
	echo ">>Copied: processes" ;
        else echo "--Failed: retrieve processes"
fi
#iostat

if $(ssh $c root@$1 "iostat -tc" >$timedate.iostat >&/dev/null );
        then $(ssh $c root@$1 "iostat -tc" >$timedate.iostat)
        echo ">>Copied: iostat" ;
        else echo "--Failed: retrieve iostat"
fi
#netstat
if $(ssh $c root@$1 "netstat -an" >$timedate.netstat >&/dev/null);
        then $(ssh $c root@$1 "netstat -an" >$timedate.netstat)
        echo ">>Copied: netstat" ;
        else echo "--Failed: retrieve netstat"
fi
#dmesg
if $(ssh $c root@$1 "dmesg" >$timedate.kernelMessageBuffer >&/dev/null );
        then $(ssh $c root@$1 "dmesg" >$timedate.kernelMessageBuffer)
        echo ">>Copied: kernel message buffer" ;
        else echo "--Failed: retrieve kernel message buffer"
fi
#running-config
if $(ssh $c root@$1 "ovsdb-client dump" > $timedate.runningConfig >&/dev/null );
        then $(ssh $c root@$1 "ovsdb-client dump" > $timedate.runningConfig)
        echo ">>Copied: running config" ;
        else echo "--Failed: retrieve running config"
fi
#startup config
if $(scp $c root@$1:/var/local/openvswitch/config.db  $timedate.startupConfig >&/dev/null );
        then echo ">>Copied: startup config" ;
        else echo "--Failed: retrieve startup config"
fi

#coredumps recursivly copy
if $(scp -r $c root@$1:/var/lib/systemd/coredump  $timedate.coredump >&/dev/null);
        then echo ">>Copied: coredumps" ;
        else echo "--Failed: retrieve coredumps"
fi
#logs recursivly copy
if $(scp -r $c root@$1:/var/log  $timedate.log >&/dev/null);
        then echo ">>Copied: logs" ;
        else echo "--Failed: retrieve logs"
fi

#failed service units
if $(ssh $c root@$1 "systemctl list-unit-files --all --state=failed" > $timedate.failed.service.units >&/dev/null );
        then $(ssh $c root@$1 "systemctl list-unit-files --all --state=failed" > $timedate.failed.service.units)
        echo ">>Copied: failed service units" ;
        else echo "--Failed: retrieve failed service units"
fi
compress $filename

