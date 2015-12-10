#!/usr/bin/env bash
#
# Collect metrics on your JVM and allow you to trace usage in graphite

# Modified: Mario Harvey - badmadrad.com

# You must have openjdk-7-jdk and openjdk-7-jre packages installed
# http://openjdk.java.net/install/

# Also make sure the user "sensu" can sudo without password

# #RED
while getopts 's:n:u:h' OPT; do
case $OPT in
s) SCHEME=$OPTARG;;
n) NAME=$OPTARG;;
u) UNAME=$OPTARG;;
h) hlp="yes";;
esac
done
#usage
HELP="
        usage $0 [ -n value -s value -u value -h ]
                -n --> NAME or name of jvm process < value
		-s --> SCHEME or server name ex. :::name:::, by default it uses the process name < value
                -u --> User name, if the Java app is run by a different user, default is empty < value
		-h --> print this help screen
"
if [ "$hlp" = "yes" ]; then
        echo "$HELP"
        exit 0
        fi

#SCHEME=${SCHEME:=0}
NAME=${NAME:=0}

if [ ! -z ${UNAME} ]
then
	UNAMEVAR="-u ${UNAME}"
fi

if [ -z ${SCHEME} ]
then
	SCHEMENAME="${NAME}"
else
	SCHEMENAME="${SCHEME}"
fi

#Get PID of JVM.
#At this point grep for the name of the java process running your jvm.
PID=$(sudo $UNAMEVAR jps | grep $NAME | awk '{ print $1}')
echo "Found ${NAME} PID, which is ${PID}"

#Get heap capacity of JVM
TotalHeap=$(sudo $UNAMEVAR jstat -gccapacity $PID  | tail -n 1 | awk '{ print ($4 + $5 + $6 + $10) / 1024 }')

#Determine amount of used heap JVM is using
UsedHeap=$(sudo $UNAMEVAR jstat -gc $PID  | tail -n 1 | awk '{ print ($3 + $4 + $6 + $8 + $10) / 1024 }')

#Determine Old Space Utilization
OldGen=$(sudo $UNAMEVAR jstat -gc $PID  | tail -n 1 | awk '{ print ($8) / 1024 }')

#Determine Permanent Space Utilization
PermGen=$(sudo $UNAMEVAR jstat -gc $PID  | tail -n 1 | awk '{ print ($10) / 1024 }')

#Determine Eden Space Utilization
ParEden=$(sudo $UNAMEVAR jstat -gc $PID  | tail -n 1 | awk '{ print ($6) / 1024 }')

#Determine Survivor Space utilization
ParSurv=$(sudo $UNAMEVAR jstat -gc $PID  | tail -n 1 | awk '{ print ($3 + $4) / 1024 }')

echo "JVMs.$SCHEMENAME.Committed_Heap $TotalHeap `date '+%s'`"
echo "JVMs.$SCHEMENAME.Used_Heap $UsedHeap `date '+%s'`"
echo "JVMs.$SCHEMENAME.Eden_Util $ParEden `date '+%s'`"
echo "JVMs.$SCHEMENAME.Survivor_Util $ParSurv `date '+%s'`"
echo "JVMs.$SCHEMENAME.Old_Util $OldGen `date '+%s'`"
echo "JVMs.$SCHEMENAME.Perm_Util $PermGen `date '+%s'`"
