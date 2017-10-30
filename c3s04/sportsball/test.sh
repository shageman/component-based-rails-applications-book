
#!/bin/bash

exit_code=0

echo "
********************************************************************************
*** Running container app specs
********************************************************************************"

export BUNDLE_GEMFILE=`pwd`/Gemfile
bundle
bundle exec rake db:drop
bundle exec rake environment db:create db:migrate
RAILS_ENV=test bundle exec rake db:create
RAILS_ENV=test bundle exec rake db:migrate
bundle exec rspec spec
((exit_code+=$?))

unset BUNDLE_GEMFILE

exit $exit_code

