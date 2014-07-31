#!/bin/bash

# UTF-8
export LANG=en_US.UTF-8

# exit on failure
set -e

#
# Usage
#

usage() {
  cat << EOF

Usage: $0 <action> <command>

A command line interface for iOS workflow.

Commands:
   version         Displays script version
   help            Displays this message

   update          Downloads latest scripts from GitHub repository

   setup           Executes setup command
   deploy          Executes deploy command

EOF

  setupinfo
  deployinfo
  about
}

#
# Help
#

about()
{
  cat << EOF
Author:
   Dal Rupnik <legoless@gmail.com>

Website:
   http://www.arvystate.net

EOF
}

setupinfo()
{
  cat << EOF
Setup commands:
   environment     Installs all gems and tools required for Dominus
   project         Creates and configures a new project
   travis          Creates .travis.yml file with correct parameters
   certificate     Creates a development certificate and adds it to all provisioning profiles

EOF
}

deployinfo()
{
  cat << EOF
Deployment commands:
   init            Installs prerequisites for building Xcode project
   pod             Finds podfile and installs pods
   prepare         Downloads and installs provisioning profiles and certificates
   build           Builds the application from source
   send            Created build, is signed and sent
   clean           Cleans all created files by other commands

   auto            Runs entire deploy process: init, pod, profile, build, send, clean

EOF
}

#
# Version
#

version()
{
  echo '[DOMINUS]: Dominus Script Version:' $SCRIPT_VERSION
}

#
# Update
#

update()
{
  echo '[DOMINUS]: Updating scripts in' $SCRIPT_PATH

  #
  # Find Dominus.sh script
  #

  DOMINUS_SCRIPT=`find . -name dominus.sh | head -n1`

  if [[ -f $DOMINUS_SCRIPT ]]; then
    echo '[DOMINUS]: Running myself, but not finding the script? Aborting...'

    exit 1;
  fi

  #
  # Get directory of Dominus script and attempt to up
  #

  DOMINUS_DIR=`basename $DOMINUS_SCRIPT`

  if [[ -d $DOMINUS_DIR'.git' ]]; then
    echo '[DOMINUS]: Found Dominus .git directory. Updating...'

    PREVIOUS_DIR=`pwd`

    cd $DOMINUS_DIR
    git pull origin master
    cd $PREVIOUS_DIR

    echo '[DOMINUS]: Successfully updated Dominus code from GitHub.'

  else
    echo '[DOMINUS]: Cannot find Dominus Git repository, unable to update. Skipping...'
  fi


  #
  # Updating submodules
  #

  git submodule foreach git pull origin master
}

#
# Setup
#

setup()
{
  case "$1" in
    environment) environment;;
    project) project;;
    travis) travis;;
    certificate) certificate;;
    *) setupinfo
    exit 1
    ;;
  esac
}

#
# Deploy
#

deploy()
{
  case "$1" in
    init) init;;
    pod) pod;;
    prepare) prepare;;
    build) build;;
    send) send;;
    clean) clean;;
    *) deployinfo
  exit 1
  ;;
  esac
}

#
# Environment
#

environment()
{
  if [[ -f $SCRIPT_PATH'setup/environment.sh' ]]; then
    $SCRIPT_PATH'setup/environment.sh'
  else
    echo '[DOMINUS]: Unable to find 'environment' script. Try to run' \"$0 update\"'.'
    exit 1
  fi
}

#
# Project
#

project()
{
  echo '[DOMINUS]: Project Not implemented'
}

#
# Travis
#

travis()
{
  if [[ -f $SCRIPT_PATH'setup/travis.sh' ]]; then
    $SCRIPT_PATH'setup/travis.sh'
  else
    echo '[DOMINUS]: Unable to find 'travis' script. Try to run' \"$0 update\"'.'
    exit 1
  fi
}

#
# Certificate
#

certificate()
{
  echo '[DOMINUS]: Certificate Not implemented'
}

#
# Init
#

init()
{
  #
  # Init script here
  #

  if [[ -f $SCRIPT_PATH'deploy/init.sh' ]]; then
    $SCRIPT_PATH'deploy/init.sh'
  else
    echo '[DOMINUS]: Unable to find 'init' script. Try to run' \"$0 update\"'.'
    exit 1
  fi
}

#
# Pod
#

pod()
{
  if [[ -f $SCRIPT_PATH'deploy/pods.sh' ]]; then
    $SCRIPT_PATH'deploy/pods.sh'
  else
    echo '[DOMINUS]: Unable to find 'pods' script. Try to run' \"$0 update\"'.'
    exit 1
  fi
}

#
# Profile
#

prepare()
{
  if [[ -f $SCRIPT_PATH'deploy/prepare.sh' ]] && [[ -f $SCRIPT_PATH'deploy/cert.sh' ]]; then
    $SCRIPT_PATH'deploy/prepare.sh' -a $ATLANTIS_PATH -c $CUPERTINO_PATH
    $SCRIPT_PATH'deploy/cert.sh'
  else
    echo '[DOMINUS]: Unable to find 'prepare' scripts. Try to run' \"$0 update\"'.'
    exit 1
  fi
}

#
# Build
#

build()
{
  if [[ -f $SCRIPT_PATH'deploy/build.sh' ]]; then
    BUILD_SCRIPT_PATH=$SCRIPT_PATH'deploy/build.sh'

    #
    # Need provisioning profile name
    #

    if [[ ! -z $DEVELOPER_PROVISIONING ]]; then
      BUILD_SCRIPT_PATH=$BUILD_SCRIPT_PATH" -f \"$DEVELOPER_PROVISIONING\""
    fi

    #
    # Add Build SDK
    #

    if [[ ! -z $BUILD_SDK ]]; then
      BUILD_SCRIPT_PATH=$BUILD_SCRIPT_PATH" -k $BUILD_SDK"
    fi

    #
    # Add Test SDK
    #

    if [[ ! -z $TEST_SDK ]]; then
      BUILD_SCRIPT_PATH=$BUILD_SCRIPT_PATH" -t $TEST_SDK"
    fi

    #
    # Add Travis CI build number
    #
    if [[ ! -z $TRAVIS_BUILD_NUMBER ]]; then
      BUILD_SCRIPT_PATH=$BUILD_SCRIPT_PATH" -b $TRAVIS_BUILD_NUMBER"
    fi

    eval $BUILD_SCRIPT_PATH
  else
    echo '[DOMINUS]: Unable to find 'build' script. Try to run' \"$0 update\"'.'
    exit 1
  fi
}

#
# Send
#

send()
{
  if [[ -f $SCRIPT_PATH'deploy/send.sh' ]]; then
    SEND_SCRIPT_PATH=$SCRIPT_PATH'deploy/send.sh'

    if [[ ! -z $DEVELOPER_PROVISIONING ]]; then
      SEND_SCRIPT_PATH=$SEND_SCRIPT_PATH" -f \"$DEVELOPER_PROVISIONING\""
    fi

    if [[ ! -z $TESTFLIGHT_API_TOKEN ]]; then
      SEND_SCRIPT_PATH=$SEND_SCRIPT_PATH" -a $TESTFLIGHT_API_TOKEN"
    fi

    if [[ ! -z $TESTFLIGHT_TEAM_TOKEN ]]; then
      SEND_SCRIPT_PATH=$SEND_SCRIPT_PATH" -t $TESTFLIGHT_TEAM_TOKEN"
    fi

    #
    # If we are on CI, this variable is likely full, we watch it for [DEPLOY
    #

#if [[ ! -z $TRAVIS_COMMIT ]]; then
#SEND_SCRIPT_PATH=$SEND_SCRIPT_PATH" -d $TESTFLIGHT_DISTRIBUTION_LIST"
#fi

    if [[ ! -z $TESTFLIGHT_DISTRIBUTION_LIST ]]; then
       SEND_SCRIPT_PATH=$SEND_SCRIPT_PATH" -d \"$TESTFLIGHT_DISTRIBUTION_LIST\""
    fi


    #If a commit message
    #is provided, script will search for [DEPLOY:<lists>]


    eval $SEND_SCRIPT_PATH
  else
    echo '[DOMINUS]: Unable to find 'send' script. Try to run' \"$0 update\"'.'
    exit 1
  fi
}

#
# Clean
#

clean()
{
  if [[ -f $SCRIPT_PATH'deploy/clean.sh' ]]; then
    $SCRIPT_PATH'deploy/clean.sh'
  else
    echo '[DOMINUS]: Unable to find 'clean' script. Try to run' \"$0 update\"'.'
    exit 1
  fi
}

#
# Auto
#

auto()
{
  echo '[DOMINUS]: Running entire deploy process. Please stand by...'

  init
  pod
  prepare
  build
  send
  clean

  echo '[DOMINUS]: Deploy is successfully finished.'
}

message()
{
  #
  # Find notify script
  #

  NOTIFY_SCRIPT=`find . -name notify.sh | head -n1`

  IFS=$'\n'

  if [[ -f $NOTIFY_SCRIPT ]]; then
    $NOTIFY_SCRIPT -m $1 -l $2 -t $3
  fi
}

#
# Global settings
#

VARIABLE_PATH='./dominus.cfg'
ATLANTIS_PATH='testflight'
CUPERTINO_PATH='iospro'

#
# Search for correct script path
#
SCRIPT_PATH=`find . -name dominus.sh | head -n1`
SCRIPT_PATH=$(dirname ${SCRIPT_PATH})
SCRIPT_PATH=$SCRIPT_PATH'/scripts/'

#echo "[DOMINUS]: Script location: $SCRIPT_PATH"

SCRIPT_VERSION='0.3.0'

#
# Protect against pull requests on CI
#
if [[ ! -z "$TRAVIS_PULL_REQUEST" ]] && [[ "$TRAVIS_PULL_REQUEST" != "false" ]]; then
  echo "[DOMINUS]: This is a pull request. No deployment will be done."
  exit 0
fi

#
# Load environment variables from file, if it exists, otherwise they should be loaded
# in environment by CI itself, to make it secure.
#

set -a

if [ -f $VARIABLE_PATH ]; then
  test -f $VARIABLE_PATH && . $VARIABLE_PATH
fi

set +a

#set -o

#
# Check if there was any command provided, otherwise display usage
#

case "$1" in
  help) usage;;
  version) version;;
  update) update;;
  setup) setup $2;;
  deploy) deploy $2;;
  *) usage
  exit 1
  ;;
esac
