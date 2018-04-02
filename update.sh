#! /usr/bin/env nix-shell
#! nix-shell -i bash -p gitAndTools.hub gitAndTools.git

git config --global hub.protocol https

if ! [ -d nixpkgs ]; then
    hub clone nixpkgs
    (cd nixpkgs;
     git remote add upstream https://github.com/NixOS/nixpkgs;
     git remote add nixpkgs-channels https://github.com/NixOS/nixpkgs-channels)
fi

(cd nixpkgs;
 git fetch nixpkgs-channels nixpkgs-unstable;
 git reset --hard nixpkgs-channels/nixpkgs-unstable;
 git checkout -B emacs-updates)

if ! [ -d emacs2nix ]; then
    git clone https://github.com/matthewbauer/emacs2nix
    (cd emacs2nix; rm -rf nixpkgs; ln -s ../nixpkgs .)
fi

if ! [ -d melpa ]; then
    git clone https://github.com/milkypostman/melpa
else
    (cd melpa; git pull origin master)
fi

pushd emacs2nix
./elpa-packages.sh \
    -o ../nixpkgs/pkgs/applications/editors/emacs-modes/elpa-generated.nix
./org-packages.sh \
    -o ../nixpkgs/pkgs/applications/editors/emacs-modes/org-generated.nix
./melpa-packages.sh \
    --melpa ../melpa \
    -o ../nixpkgs/pkgs/applications/editors/emacs-modes/melpa-generated.nix
./melpa-stable-packages.sh \
    --melpa ../melpa \
    -o \
    ../nixpkgs/pkgs/applications/editors/emacs-modes/melpa-stable-generated.nix
popd

pushd nixpkgs
git add pkgs/applications/editors/emacs-modes/elpa-generated.nix
git commit -m "elpa-packages $(date -Idate)"
git add pkgs/applications/editors/emacs-modes/melpa-generated.nix
git commit -m "melpa-packages $(date -Idate)"
git add pkgs/applications/editors/emacs-modes/melpa-stable-generated.nix
git commit -m "melpa-stable-packages $(date -Idate)"
git add pkgs/applications/editors/emacs-modes/org-generated.nix
git commit -m "org-packages $(date -Idate)"
git push --set-upstream origin emacs-updates --force
hub pull-request -F - <<EOF
Automated Emacs updates

These are automated Emacs updates, generated with emacs2nix through a
Travis cron job. Sources currently pulled are ELPA, MELPA, and Org. If
there is any issue, please file it at
https://github.com/matthewbauer/elpahelpa.

EOF
popd
