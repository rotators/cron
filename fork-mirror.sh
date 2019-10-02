#!/bin/bash
#
# TODO this should be made into legit action some day...
#      ...but we'd have to use js <thunder.wav>...
#      ...or wait when/if https://github.community/t5/GitHub-Actions/Feature-request-Shell-script-as-type-of-action/m-p/30671#M506 is added
#
# - uses: rotators/actions/fork-mirror@???
#   with:
#    upstream:   https://github.com/cvet/fonline.git
#    fork:       https://github.com/rotators/fonline.git
#    auth:       ${{ secrets.TOKEN }}

set -e

if [ $# -lt 1 ]; then
	echo "Usage: $0 <upstream> [fork] [auth]"
	exit 1
fi

upstream=$1
fork=$2
auth=$3

if [ -n "${fork}" ]; then
	echo "Mirror ${upstream} -> ${fork}"
fi

# TODO custom directory
fork_dir="$HOME/fork"

echo ::group::Clone upstream
rm -fR ${fork_dir}
git clone --mirror "${upstream}" "${fork_dir}" 2>&1 && cd "${fork_dir}"
echo ::endgroup::

echo ::group::Configure upstream
git config --unset remote.origin.fetch
git config --add remote.origin.fetch +refs/heads/*:refs/heads/*
git config --add remote.origin.fetch +refs/tags/*:refs/tags/*
cat config
echo ::endgroup::

echo ::group::Show refs
git show-ref
echo ::endgroup::

echo ::group::Remove pull requests
git show-ref | cut -d' ' -f2 | grep '^refs/pull/' | xargs -r -L1 git update-ref -d
git show-ref
echo ::endgroup::

echo ::group::Synch
git fetch --prune
echo ::endgroup::

if [ -n "${fork}" ]; then
	if [ -n "${auth}" ]; then
		echo ::group::Configure fork
		git remote add fork $(echo "${fork}" | sed -re "s|^([a-z]+)://|\1://${auth}@|") #"
		git config --unset remote.fork.fetch
		git config --add remote.fork.mirror true
		echo ::endgroup::

		echo ::group::Push
		git push --prune fork
		echo ::endgroup::
	else
		echo ::group::Configure fork
		git remote add fork ${fork}
		cat config
		echo ::endgroup::
	fi
fi
