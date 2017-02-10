#!/bin/bash

echo "### Running tests"
bower cache clean && bower install && grunt test --browsers=PhantomJS; export RESULT=$?

if [[ "$RESULT" == 0 ]]; then
  echo "JS tests passed"
else
  exit "$RESULT"
fi
cd grails/ag-plugin && ./gradlew check

echo "### Running publishing"

if [[ $TRAVIS_BRANCH == 'grails3' && $TRAVIS_PULL_REQUEST == 'false' ]]; then
	echo "### publishing plugin to bintray"
	./gradlew assemble check bintrayUpload

else
  echo "TRAVIS_BRANCH: $TRAVIS_BRANCH"
  echo "TRAVIS_REPO_SLUG: $TRAVIS_REPO_SLUG"
  echo "TRAVIS_PULL_REQUEST: $TRAVIS_PULL_REQUEST"
fi