#!/bin/bash
#
# TODO this should be made into legit action some day...
#      ...but we'd have to use js <thunder.wav>...
#      ...or wait when/if https://github.community/t5/GitHub-Actions/Feature-request-Shell-script-as-type-of-action/m-p/30671#M506 is added
#
# - uses: rotators/actions/fork-merge@???
#   with:
#    upstream:   https://github.com/phobos2077/sfall.git
#    fork:       https://github.com/rotators/sfall.git
#    branches:   [master, develop, 3.8-maintenance]
#    auth:       ${{ secrets.TOKEN }}

set -e

if [ $# -lt 1 ]; then
	echo "Usage: $0 <upstream> <fork> [auth] <branches...>"
	exit 1
fi

upstream=$1
fork=$2
auth=$3
branches=${@:4}

if [ -z "${upstream}" ]; then
	echo "Missing <upstream>"
	exit 1
elif [ -z "${fork}" ]; then
	echo "Missing <fork>"
	exit 1
elif [ -z "${branches}" ] || [ "${#branches[@]}" -lt 1 ]; then
	echo "Missing <branches>"
	exit 1
fi

# TODO custom directory
fork_dir="$HOME/fork"

echo "${upstream} -[${branches[@]}]-> ${fork}"

for branch in ${branches[@]}; do
	echo ::group::Clone branch $branch
	rm -fR "${fork_dir}-${branch}"
	if [ -n "${auth}" ]; then
		git clone --branch=${branch} $(echo "${fork}" | sed -re "s|^([a-z]+)://|\1://${auth}@|") "${fork_dir}-${branch}" #"
	else
		git clone --branch=${branch} ${fork} "${fork_dir}-${branch}"
	fi
	cd "${fork_dir}-${branch}"
	echo ::endgroup::

	echo ::group::Configure upstream
	git remote add upstream ${upstream}
	echo ::endgroup::

	echo ::group::Synch
	git fetch upstream
	echo ::endgroup::

	echo ::group::Merge branch $branch
	git merge --no-edit upstream/${branch}
	echo ::endgroup::

	if [ -n "${auth}" ]; then
		echo ::group::Push branch $branch
		git push origin ${branch}
		git push --tags
		echo ::endgroup::
	fi
done
