
#!/bin/bash

exit_code=0

echo "
********************************************************************************
*** Running teams_store MEM engine specs
********************************************************************************"

bundle install | grep Installing
bundle exec rspec spec
((exit_code+=$?))

exit $exit_code

