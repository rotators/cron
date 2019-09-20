#!/bin/bash
#
# UNUSED (for now)
#
# TODO this should be made into legit action some day if we want to mirror more repos...
#      ... but we'd have to use js <thunder.wav> ...
#      ...or wait when/if https://github.community/t5/GitHub-Actions/Feature-request-Shell-script-as-type-of-action/m-p/30671#M506 is added
#
# - uses: rotators/gha-fork/mirror@???
#   with:
#    upstream:   https://github.com/cvet/fonline.git
#    fork:       rotators/fonline
#    user:       ???
#    token:      ???
#    user-name:  ???
#    user-email: ???

set -e

if [ $# -lt 1 ]; then
	echo "Usage: $0 <upstream> [fork] [user] [token] [user_name] [user_email]"
	exit 1
fi

upstream=$1

fork=$2
user=$3
token=$4

user_name=$5
user_email=$6

rm -fR fork
git clone --mirror ${upstream} fork && cd fork

echo Patch config...
git config --unset remote.origin.fetch
git config --add remote.origin.fetch +refs/heads/*:refs/heads/*
git config --add remote.origin.fetch +refs/tags/*:refs/tags/*
cat config

echo Remove pull requests...
git show-ref | cut -d' ' -f2 | grep 'pull' | xargs -r -L1 git update-ref -d
git show-ref

echo Synch...
git fetch --prune

if [ ! -z "${fork}" ]; then
	if [ ! -z "$user" ] && [ ! -z "$token" ]; then
		git remote add fork https://${user}:${token}@github.com/${fork}
	else
		git remmote add fork https://github.com/${fork}
	fi

	git config --unset remote.fork.fetch
	git config --add remote.fork.mirror true

	# is that even needed?
	if [ ! -z "$user_name" ]; then
		git config --global user.name ${user_name}
	fi

	# is that even needed?
	if [ ! -z "${user_email}" ]; then
		git config --global user.email ${user_email}
	fi

	# push only if user/token is set
	if [ ! -z "$user" ] && [ ! -z "$token" ]; then
		git push --prune fork
	fi
fi
