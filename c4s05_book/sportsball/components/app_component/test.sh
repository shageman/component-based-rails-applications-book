
#!/bin/bash

exit_code=0

echo "
********************************************************************************
*** Running app component engine specs
********************************************************************************"

export BUNDLE_GEMFILE=`pwd`/Gemfile
bundle
bundle exec rake db:create db:migrate
RAILS_ENV=test bundle exec rake db:create
RAILS_ENV=test bundle exec rake db:migrate
bundle exec rspec spec
((exit_code+=$?))

unset BUNDLE_GEMFILE

exit $exit_code

