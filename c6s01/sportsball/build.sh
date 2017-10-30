#!/bin/bash

result=0

echo "### TESTING EVERYTHING WITH TEAMS DB"

rm components/teams_store
ln -s teams_store_db components/teams_store

for test_script in $(find . -name test.sh | sort); do
  pushd `dirname $test_script` > /dev/null
  ./test.sh
  ((result+=$?))
  popd > /dev/null
done

echo "### TESTING EVERYTHING WITH TEAMS IN MEM"

rm components/teams_store
ln -s teams_store_mem components/teams_store

for test_script in $(find . -name test.sh | sort); do
  pushd `dirname $test_script` > /dev/null
  ./test.sh
  ((result+=$?))
  popd > /dev/null
done

if [ $result -eq 0 ]; then
	echo "SUCCESS"
else
	echo "FAILURE"
fi

exit $result

