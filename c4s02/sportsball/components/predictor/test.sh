
#!/bin/bash

exit_code=0

echo "
********************************************************************************
*** Running predictor gem specs
********************************************************************************"

export BUNDLE_GEMFILE=`pwd`/Gemfile
bundle install | grep Installing
bundle exec rspec spec
((exit_code+=$?))

exit $exit_code

