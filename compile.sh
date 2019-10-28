#!/bin/bash

# bash script for automating compiling binaries on the ulab servers.
# This script assumes you have passwordless key-based authentication set up.

# port by default, this can be changed
PORT=22
SSHVM=0
MAKEARGS=""

		
while getopts ":a:c:d:p:r:s:u:v:y" arg; do
	case $arg in
		a) MAKEARGS=$OPTARG		# arguments to pass to make (if necessary)
			;;
		d) DIR=$OPTARG			# location of directory to compile
			;;
		# TODO: deprecated by a argument, remove eventually
		c) CLEAN="clean"		# are we doing make clean?
			;;
		u) USERNAME=$OPTARG		# remote username for server (required)
			;;
		r) REMOTE=$OPTARG		# server name / IP (required)
			;;
		p) PORT=$OPTARG			# SSH port (22 by default)
			;;
		s) SSHVM=1			# will we need to SSH into the VM on a remote server?
			;;
		v) VMREMOTE=$OPTARG		# VM to SSH into (required)
			;;
		y) VMUSERNAME=$OPTARG		# username for VM (uses normal username by default)
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

if [[ -n $CLEAN ]]; then
	cd $DIR && make clean
	#exit 0
fi

# send files to remote server for compilation
# TODO: replace this with rsync eventually
scp -r $DIR $USERNAME@$REMOTE:.temp-mp/

# this script assumes that ulab-compile is in the path
# and is marked as executable
ulab-compile $BASEDIR "$CLEAN" $USERNAME $REMOTE $MAKEARGS

# for cases where we don't want to send files to the VM; we just want to
# test whether or not everything compiles correctly
if [[ $VMREMOTE -eq 0 ]]; then
	exit 0
fi

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
# either be hosted locally or remotely.
# the user will be able to interact with the virtual SAPC after this.
tutor-send $VMREMOTE $(basename $DIR/*.lnx) $SSHVM $VMUSERNAME
