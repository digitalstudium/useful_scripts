# $1 - path/to/module/
# $2 - number-of-submodule
# $3 - submodule merging branch
# $4 - repo name
git remote rm submodule_origin
git rm $1
git commit -m "Remove $4 submodule"
git remote add submodule_origin ssh://<repo-url>/$4.git
git fetch submodule_origin
git lfs fetch submodule_origin --all
git branch merge-branch-$2 submodule_origin/$3
git checkout merge-branch-$2
git lfs fetch submodule_origin --all
mkdir -p $1
git ls-tree -z --name-only HEAD | xargs -0 -I {} git mv {} $1
git commit -m "Moved files to $1"
git checkout feature/merge-submodules
git merge --allow-unrelated-histories merge-branch-$2
git push --set-upstream origin feature/merge-submodules
