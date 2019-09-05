#!/bin/sh

set -e  # exit on script error

# Run from project root
test ! -d scripts && echo "scripts dir not found in $PWD, exiting..." && exit 1

echo "# Testing identifier resolution"

echo "## objectstore resolution"
./config/delegates_test.rb objectstore:beeldbank-B00000026214.jpg "https://f8d5776e78674418b6f9a605807e069a.objectstore.eu/Images/beeldbank-B00000026214.jpg"
echo ""

echo "## edepot resolution"
./config/delegates_test.rb edepot:SA$00702$SA00632608_00001.jpg "https://bwt.uitplaatsing.hcp-a.basis.lan/rest/SA/00702/SA00632608_00001.jpg" false
echo ""

echo "## beeldbank resolution"
./config/delegates_test.rb beeldbank:B00000030938 "https://beeldbank.amsterdam.nl/component/ams_memorixbeeld_download/?format=download&id=B00000030938"
echo ""

echo "## filesystem resolution"
./config/delegates_test.rb fs:test.jpg "/images/fs:test.jpg"
echo ""


echo "# Testing whitelisting"

echo "## Whitelisted"
./config/delegates_test.rb edepot_local:ST$00014$ST00000109_00001.JPG "/images/edepot/ST-00014-ST00000109_00001.JPG"
echo ""

echo "## Not whitelisted"
./config/delegates_test.rb edepot_local:ST$00001$ST00005_00001.jpg "/images/edepot/ST-00001-ST00005_00001.jpg" false
echo ""
