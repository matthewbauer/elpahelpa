#! /usr/bin/env nix-shell
#! nix-shell -p gitAndTools.hub gitAndTools.git -i bash

if ! [ -d nixpkgs ]; then
    hub clone nixpkgs
    (cd nixpkgs; git remote add upstream https://github.com/NixOS/nixpkgs)
fi

(cd nixpkgs; git fetch upstream/master; git reset --hard upstream/master)

if ! [ -d emacs2nix ]; then
    git clone https://github.com/matthewbauer/emacs2nix
    (cd emacs2nix; git submodule update --init)
fi

if ! [ -d melpa ]; then
    git clone https://github.com/milkypostman/melpa
else
    (cd melpa; git pull origin master)
fi

cd emacs2nix
./elpa-packages.sh -o ../nixpkgs/pkgs/applications/editors/emacs-modes/elpa-generated.nix
./melpa-packages.sh --melpa melpa -o ../nixpkgs/pkgs/applications/editors/emacs-modes/melpa-generated.nix
./melpa-stable-packages.sh --melpa melpa -o ../nixpkgs/pkgs/applications/editors/emacs-modes/melpa-stable-generated.nix
./org-packages.sh -o ../nixpkgs/pkgs/applications/editors/emacs-modes/org-generated.nix

cd ../nixpkgs
git add pkgs/applications/editors/emacs-modes/elpa-generated.nix
git commit -m "elpa-packages $(date -Idate)"
git add pkgs/applications/editors/emacs-modes/melpa-generated.nix
git commit -m "melpa-packages $(date -Idate)"
git add pkgs/applications/editors/emacs-modes/melpa-stable-generated.nix
git commit -m "melpa-stable-packages $(date -Idate)"
git add pkgs/applications/editors/emacs-modes/org-generated.nix
git commit -m "org-packages $(date -Idate)"

git push --set-upstream origin master --force
hub pull-request <<EOF
Automated Emacs updates

These are automated Emacs updates, generated with emacs2nix. Source
currently pulled are ELPA, MELPA, and Org. This pull request should be
created automatically by @EmacsBot. If there is any issue, please
file it at https://github.com/matthewbauer/elpahelpa.

EOF
