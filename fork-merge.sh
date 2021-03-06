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
#    mirror:     true
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

mirror=1

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

echo "Merge ${upstream} -[${branches[@]}]-> ${fork}"

for branch in ${branches[@]}; do
	echo ::group::Clone branch $branch

	cd /
	branch_dir="${fork_dir}-${branch}"
	rm -fR "${branch_dir}"

	if [ -n "${auth}" ]; then
		git clone --branch=${branch} $(echo "${fork}" | sed -re "s|^([a-z]+)://|\1://${auth}@|") "${branch_dir}" #"
	else
		git clone --branch=${branch} ${fork} "${branch_dir}"
	fi
	cd "${branch_dir}"
	echo ::endgroup::

	git remote add upstream ${upstream}

	echo ::group::Synch
	git fetch upstream
	git checkout ${branch}
	echo ::endgroup::

	echo ::group::Merge branch $branch
	git merge --no-edit upstream/${branch} 2>&1 || true
	echo ::endgroup::

	reset=0
	if [ "${mirror}" -gt 0 ]; then
		hash_origin=`git log -n 1 --pretty=format:"%H" ${branch}`
		hash_upstream=`git log -n 1 --pretty=format:"%H" upstream/${branch}`

		if [ "${hash_origin}" != "${hash_upstream}" ]; then
			echo Bad merge
			for log in ${branch} upstream/${branch}; do
				echo ::group::git log ${log}
				git --no-pager log -n 2 ${log}
				echo ::endgroup::
			done
			echo ::group::Reset branch $branch
			reset=1
			git reset --hard upstream/${branch}
			echo ::endgroup::
		fi
	fi

	if [ -n "${auth}" ]; then
		if [ $reset -eq 0 ]; then
			echo ::group::Push branch $branch
			git push origin ${branch}
			git push --tags
			echo ::endgroup::
		else
			echo ::group::Force push branch $branch
			git push --force origin ${branch}
			git push --tags
			echo ::endgroup::
		fi
	fi

	rm -fR "${branch_dir}"
	cd /
done
