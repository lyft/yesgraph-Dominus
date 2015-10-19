#!/bin/bash

# exit on failure
set -e

#
# Outputs reporter script location
#

run_tests()
{
  #
  # Fill defaults
  #

  if [[ -z $DIR_PATH ]]; then
    DIR_PATH=$(pwd)
  fi

  if [[ -z BUILD_CONFIG ]]; then
    BUILD_CONFIG='Release'
  fi

  #
  # Search for workspace if project and workspace not set
  #

  if [[ -z $WORKSPACE ]] && [[ -z $PROJECT ]]; then
    search_targets
  fi

  #
  # Check if we have workspace or project at least
  #
  if [[ -z $WORKSPACE ]] && [[ -z $PROJECT ]]; then
    message "test" "Nothing to test, aborting..." trace error
    exit 1
  elif [[ ! -z $WORKSPACE ]]; then
    message "test" "Testing Workspace: $WORKSPACE" debug normal
  elif [[ ! -z $PROJECT ]]; then
    message "test" "Testing Project: $PROJECT" debug normal
  fi

  set_build_path

  #
  # Load other parameters from the XCode itself
  #

  message "test" "Source path: $BUILD_PATH" trace normal

  select_scheme

  #
  # Check for scheme
  #

  if [[ -z $SCHEME ]]; then
    message "test" "No scheme found in project (did you set it as shared?). Aborting..." warn error
    exit 1
  fi

  #
  # Load config from scheme file on Test action
  #

  BUILD_CONFIG=$(find_config $SCHEME_FILE Test)

  #
  # Build and test paths need to go under build directory, which is usually under .gitignore
  #

  TEST_PATH="$BUILD_PATH/build/test/"

  TEST_COMMAND=""

  if [[ ! -z $WORKSPACE ]]; then
    TEST_COMMAND="xctool -workspace $WORKSPACE"
  elif [[ ! -z $PROJECT ]]; then
    TEST_COMMAND="xctool -project $PROJECT"
  fi

  TEST_COMMAND=$TEST_COMMAND" -scheme $SCHEME"

  #
  # Append build configuration
  #

  if [[ ! -z $BUILD_CONFIG ]]; then
    message "test" "Using Test Action build config in scheme: $BUILD_CONFIG" debug normal

    TEST_COMMAND=$TEST_COMMAND" -configuration $BUILD_CONFIG"
  else
    message "test" "Build configuration not detected, using xcodebuild..." info warning
  fi


  if [[ $TEST_SDK == *simulator* ]]; then
    TEST_COMMAND=$TEST_COMMAND" -arch i386"
  fi

  #
  # Prepare commands
  #
  TEST_COMMAND=$TEST_COMMAND" CONFIGURATION_BUILD_DIR=$TEST_PATH"

  if [[ $TEST_SDK == *simulator* ]]; then
    TEST_COMMAND=$TEST_COMMAND" VALID_ARCHS='i386'"
  fi

  REPORTER=$(reporter);

  if [[ ! -z $REPORTER ]]; then
    TEST_COMMAND_REPORTER=$TEST_COMMAND" -reporter $REPORTER"
  else
    TEST_COMMAND_REPORTER=$TEST_COMMAND
  fi

  #
  # Check if we need to clean
  #

  TEST_CLEAN_COMMAND=$TEST_COMMAND" clean"

  setup_bootstrap
  
  execute_rake_test
  execute_test
}

execute_test()
{
  #
  # Executing built in Xcode tests...
  #

  if [[ ! -z $TEST_SDK ]]; then

    if [[ -d $TEST_PATH ]]; then
      message "test" "Test build already exists. Cleaning..." debug normal

      eval $TEST_CLEAN_COMMAND > /dev/null
    fi

    message "test" "Testing build: $TEST_SDK" debug normal

    TEST_COMMAND=$TEST_COMMAND" test -test-sdk $TEST_SDK"
    TEST_COMMAND_REPORTER=$TEST_COMMAND_REPORTER" test -test-sdk $TEST_SDK"

    if [[ ! -z $BUILD_SDK ]]; then
      TEST_COMMAND=$TEST_COMMAND" test -sdk $BUILD_SDK"
      TEST_COMMAND_REPORTER=$TEST_COMMAND_REPORTER" test -sdk $BUILD_SDK"
    fi

    #
    # Code Coverage requires link to the project, try to find it
    #

    if [[ -z $PROJECT ]]; then
      PROJECT=$(find_project)
    fi

    if [ "$GENERATE_CODE_COVERAGE" == true ] && [[ ! -z $PROJECT ]]; then
      message "test" "Setuping project for Code Coverage: $PROJECT" info normal

      gem_install "slather"

      slather setup $PROJECT
    fi

    message "test" "Test command: $TEST_COMMAND" trace normal

    TEST_EXECUTE=`eval $TEST_COMMAND_REPORTER || true`

    #
    # Parsing Test Result
    #

    NO_FAILURES=`echo $TEST_EXECUTE | grep ' 0 errored' | head -1`
    NO_ERRORS=`echo $TEST_EXECUTE | grep ' 0 failed' | head -1`

    TEST_EXECUTE=`echo $TEST_EXECUTE | sed -e 's/^ *//' -e 's/ *$//'`

    if [[ ! -z $NO_FAILURES ]] && [[ ! -z $NO_ERRORS ]]; then
      message "test" "Test complete (<b>$TEST_SDK</b>): <b>$SCHEME</b> ($TEST_EXECUTE)" warn success

      generate_code_coverage

    else
      message "test" "Test failed (<b>$TEST_SDK</b>): <b>$SCHEME</b> ($TEST_EXECUTE)" warn error

      generate_code_coverage

      #echo $TEST_COMMAND

      eval $TEST_CLEAN_COMMAND > /dev/null

      LOG_REPORT_PATH=$(create_report_path tests $TEST_SDK)

      #eval $TEST_COMMAND' -reporter junit:./report/'$LOG_REPORT_PATH'.xml' > './report/'$LOG_REPORT_PATH'_xcode.log'
      `eval $TEST_COMMAND -reporter plain:"./report/"$LOG_REPORT_PATH"_test_xcode.log" || true`
      #eval $TEST_COMMAND

      cat './report/'$LOG_REPORT_PATH'_test_xcode.log'
      
      exit 1
    fi
  fi
}

execute_rake_test()
{
  #
  # Testing, always run rake script, no matter the situation
  #

  RAKE_SCRIPT=`find . -name Rakefile | head -n1`

  if [[ -f $RAKE_SCRIPT ]]; then

    message "test" "Running Rake script..." debug normal

    $($RAKE_SCRIPT test)

    message "test" "Rake testing finished." trace normal
  fi
}

generate_code_coverage()
{
  #
  # Slather knows how to upload to certain services, but only if configuration file is defined.
  #

  SLATHER_FILE=$(find_file '.slather.yml')

  set +e

  if [[ ! -z $SLATHER_FILE ]]; then

    gem_install "slather"

    message "test" "Detected Slather file, running code coverage upload..." trace normal

    slather

    message "test" "Slather upload finished." debug success
  fi

  if [ "$GENERATE_CODE_COVERAGE" == true ] && [[ ! -z $PROJECT ]]; then
    gem_install "slather"

    message "test" "Generating Code Coverage for: $PROJECT" trace normal

    slather coverage --html $PROJECT

    message "test" "Code Coverage report generated." debug success
  fi

  set -e
}