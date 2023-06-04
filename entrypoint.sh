#!/bin/bash
set -e
set -u

# Clone Logseq
cd /root
git clone -b ${LOGSEQ_VERSION} --depth 1 https://github.com/logseq/logseq.git
cd logseq

# Apply patch containing changes to build rpm package
patch -p1 </root/logseq.patch

#Fix because RPATH for dugite git is invalid and build would fail without this
export QA_RPATHS=$(( 0x0002 )) 

# Build Logseq
yarn install --frozen-lockfileyarn
yarn release-electron

# Export rpm and clean
mkdir -p /output
cp /root/logseq/static/out/make/rpm/x64/logseq-*.rpm /output

echo -e "\e[42;30mDone !\e[0m"