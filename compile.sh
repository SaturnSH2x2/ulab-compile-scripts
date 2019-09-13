#!/bin/bash -x

# bash script for automating compiling binaries on the ulab servers.
# This script assumes you have passwordless key-based authentication set up.

# port by default, this can be changed
PORT=22
SSHVM=0

		
while getopts ":c:d:p:r:s:u:v:y" arg; do
	case $arg in
		d) DIR=$OPTARG			# location of directory to compile
			;;
		c) CLEAN="clean"		# are we doing make clean?
			;;
		u) USERNAME=$OPTARG		# remote username for server
			;;
		r) REMOTE=$OPTARG		# server name / IP
			;;
		p) PORT=$OPTARG			# SSH port (22 by default)
			;;
		s) SSHVM=1			# will we need to SSH into the VM on a remote server?
			;;
		v) VMREMOTE=$OPTARG
			;;
		y) VMUSERNAME=$OPTARG
			;;
	esac
done

if [[ -z $DIR ]]; then
	DIR=$(pwd)
	echo $DIR
fi

# default to normal username if not specified
if [[ -z $VMUSERNAME ]]; then
	VMUSERNAME=$USERNAME
fi

BASEDIR=$(basename $DIR)

# we don't need to compile the files remotely for cleaning
if [[ -n $CLEAN ]]; then
	cd $DIR && make clean
	#exit 0
fi

# send files to remote server for compilation
# TODO: replace this with rsync eventually
scp -r $DIR $USERNAME@$REMOTE:.temp-mp/

# this script assumes that ulab-compile is in the path
# and is marked as executable
ulab-compile $BASEDIR "$CLEAN" $USERNAME $REMOTE

# copy lnx files and syms back here
# TODO: also replace this with rsync
scp $USERNAME@$REMOTE:.temp-mp/$BASEDIR/*.lnx $DIR
scp $USERNAME@$REMOTE:.temp-mp/$BASEDIR/syms $DIR

# send lnx file to VM
# TODO: handle cases where the VM is running on a remote server
if [[ $SSHVM -eq 0 ]]; then
	scp $DIR/*.lnx tuser@$VMREMOTE:executables/
fi

# this script expects the VMs to be already running. They can
# either be hosted locally or remotely
tutor-send $VMREMOTE $(basename $DIR/*.lnx) $SSHVM $VMUSERNAME &
#sleep 5

# set up GDB session

