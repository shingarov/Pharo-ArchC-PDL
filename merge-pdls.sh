#!/bin/bash

set -e

error() {
	echo "ERROR: $1"
	exit 1
}

merge() {
	local branches=""
	local branches_and_paths=""
	while read path repo branch
	do
		git remote add -f "to-merge-$path" "$repo"
		branches="$branches to-merge-$path/$branch"
		branches_and_paths="$branches_and_paths $path:to-merge-$path/$branch"
		echo " * $(git log -1 --pretty=format:\"%h\" to-merge-$path/$branch) from $repo into $path" >> $commitmsg
	done

	git merge -s ours --no-commit --allow-unrelated-histories $branches

	for branch_and_path in $branches_and_paths
	do
		local path=$(echo $branch_and_path | cut -d : -f 1)
		local branch=$(echo $branch_and_path | cut -d : -f 2)
		git read-tree --prefix=$path -u "$branch"
	done
}

if [ -z "$1" ]; then
	echo "Usage: $0 new-repo-path"
elif [ ! -x "$1" ]; then
	git init "$1"
elif [ -d "$1/.git" ]; then
	error "$1 already exists, either remove of choose another"
fi

commitmsg=$(mktemp)
echo "Merge individual architectures into a single repository" > $commitmsg
echo "" >> $commitmsg

cp "$0" "$1"

pushd $1

git add $(basename $0)
git commit -m "Add \`$(basename $0)\` script to merge individual architecures"


merge <<END
arm 		https://github.com/shingarov/arm.git		good
x86 		https://github.com/shingarov/x86.git		bee
powerpc		https://github.com/shingarov/powerpc.git	good
riscv		https://github.com/shingarov/riscv.git 		master
mips 		https://github.com/shingarov/mips.git		master
sparc		https://github.com/shingarov/sparc.git 		gdb-descriptors
END

git commit -F "$commitmsg"

git rm $(basename $0)
git commit -m "Remove \`$(basename $0)\` script as it's no longer needed"
git log

popd
