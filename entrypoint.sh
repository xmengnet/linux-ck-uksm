#!/bin/bash

git clone "https://github.com/antman666/auto_pkgbuild"
cd "auto_pkgbuild"
makepkg -sf --noconfirm --skippgpcheck
mv *.zst /auto_pkgbuild
