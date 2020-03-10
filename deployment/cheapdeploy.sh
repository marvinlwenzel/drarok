#!/bin/bash

# Default configuration

SHOULD_SOURCE_ENVFILE=TRUE
FORCE_RESTART=TRUE
VERBOSE=FALSE


# Helping functions

verbose () {
  [ $VERBOSE == TRUE ] && echo $@
}

err_exit () {
  echo $@ >&2
  echo "Abort." >&2
  exit 1
}

# Parse arguments

for i in "$@"
do
case $i in

    # see https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash

    # -e=*|--extension=*)
    # EXTENSION="${i#*=}"
    # shift # past argument=value
    # ;;

    --force-restart)
    FORCE_RESTART=TRUE
    shift
    ;;
    --no-force-restart)
    FORCE_RESTART=FALSE
    shift
    ;;
    --no-envfiles)
    SHOULD_SOURCE_ENVFILE=FALSE
    shift
    ;;
    -v|--verbose)
    VERBOSE=TRUE
    shift
    ;;
    -c=*|--cred-dir-host=*)
    DRAROK_CRED_DIR_HOST="${i#*=}"
    shift
    ;;
    --dry-run)
    DRY_RUN=TRUE
    shift
    ;;
    -h|--help)
    help="$0 usage.

-h|--help           Show this.

--no-envfiles       Do not source any .env files. By default, a file named .env is
                    sourced, otherwise all files matching *.env are sourced. If none
                    are found, exit 1.

--no-force-restart  Before restarting the container, check if the image and
                    the running container have different SHA's. If they are the
                    same, do not restart the container.

--force-restart     Default behaviour. Restart the container ignoring that it
                    might restrat with the same image as it already runs on.

-r=<REP>|--repository=<REP>
                    Set the git repository to <REP>. Does NOT imply
                    --clone-if-missing.

-c=<DIR>>|--cred-dir-host=<DIR>
                    Sets the directory that contains the credntial files on the
                    host. Must be set.

-v|--verbose        MIGHT LOG CREDENTIALS. CARE.

--dry-run           Stops before going into DRAROK_WORKDIR and doing stuff.
"
    echo "$help"
    exit 0
    ;;
    *)
    err_exit "Unknown option $i"
    ;;
esac
done


# Not-to-be-configured variables observing runtime

AT_LEAST_ONE_ENVFILE_WAS_SOURCED=FALSE


# Sourcing .env files if not specified otherwise

if [[ $SHOULD_SOURCE_ENVFILE == TRUE ]]
then

  # If there is a ".env", source it.
  # Otherwise, source all "*.env" files located in current WORKDIR

  if [[ -f .env ]]
  then
      verbose "Solely sourcing .env"
      source .env

      AT_LEAST_ONE_ENVFILE_WAS_SOURCED=TRUE
  else
      for envfile in drarok.env drarok_deployment.env
      do
          verbose "Sourcing $envfile"
          source $envfile
          AT_LEAST_ONE_ENVFILE_WAS_SOURCED=TRUE
      done
  fi
fi


# Check for required options being set
# Maybe you wanna use this when working in the script
# grep -o '\$[A-Z_][A-Z_]*' cheapdeploy.sh  | sort | uniq | grep -o "[A-Z_]*"
# grep -o '\$DRAROK[A-Z_]*' cheapdeploy.sh  | sort | uniq | grep -o "[A-Z_]*"
# use this to make the output one like
# grep -o '\$[A-Z_][A-Z_]*' cheapdeploy.sh  | sort | uniq | grep -o "[A-Z_]*" | sed ':a;N;$!ba;s/\n/ /g'
# grep -o '\$DRAROK[A-Z_]*' cheapdeploy.sh  | sort | uniq | grep -o "[A-Z_]*" | sed ':a;N;$!ba;s/\n/ /g'

for mandatory_variable_name in DRAROK_CONTAINER_NAME DRAROK_CRED_DIR_CONTAINER DRAROK_CRED_DIR_HOST \
 DRAROK_IMAGE_NAME DRAROK_IMAGE_VERSION DRAROK_TOKEN DRAROK_WORKDIR
do

  # https://unix.stackexchange.com/questions/41292/variable-substitution-with-an-exclamation-mark-in-bash
  # Inderect varibale addressing - bash pointers. Lit af
  # When the variable named as the content of the variable mandatory_variable_name is empty or not set
  if [ ! -z ${!mandatory_variable_name} ]
  then
    verbose "$mandatory_variable_name set to ${!mandatory_variable_name}"
  else
    # Log to stderr which varibales are missing.
    # For diagnostics, do not exit after the fist but exit after all are checked.
    echo "$mandatory_variable_name is not set." >&2
    MANDATORY_VARIABLE_MISSING=TRUE
  fi
done

# Abort if at least one is missing.
[ $MANDATORY_VARIABLE_MISSING == TRUE ] && err_exit "Mandatory variable(s) missing."


# If something should have been sourced, but nothing was sourced: fail.

if [[ $SHOULD_SOURCE_ENVFILE == "TRUE" && ! $AT_LEAST_ONE_ENVFILE_WAS_SOURCED == "TRUE" ]]
then
    echo "Did not find any environment variables. If this is intended, run again with --no-envfiles" >&2
fi


# Stop before actually doing something if running dry.

if [ $DRY_RUN == TRUE ]
then
  echo "Dry run. Stopping now."
  exit 0
fi


# If DRAROK_WORKDIR exists, go in there

[ -d $DRAROK_WORKDIR ] || err_exit "DRAROK_WORKDIR $DRAROK_WORKDIR does not exist."
cd $DRAROK_WORKDIR


# No repository, no deployment

git status >/dev/null 2>&1 || err_exit "There appears to be no git repository in here."


# Update repository

git pull || err_exit "Git pull failed."


# Build docker image locally

docker build . -t $DRAROK_IMAGE_NAME:$DRAROK_IMAGE_VERSION || err_exit "Could not build docker image"


AVAILABLE_VERSION=$(docker images | grep $DRAROK_IMAGE_NAME | grep $DRAROK_IMAGE_VERSION | awk '{print $3}')
CURRENTLY_RUNNING_VERSION=$(docker inspect $DRAROK_CONTAINER_NAME | awk -F":" '/Image.*sha256/ {print $3}' | head -c 12)

verbose "Available version: $AVAILABLE_VERSION"
verbose "Currently running version: $CURRENTLY_RUNNING_VERSION"


# IF there is is something new or restart is forced, actually restart it.

if [ $FORCE_RESTART == "TRUE" ] || [ ! $AVAILABLE_VERSION == $CURRENTLY_RUNNING_VERSION ]
then
  [ -d deploy ] && echo l || echo r
  docker stop $DRAROK_CONTAINER_NAME && verbose "Did stop container" || echo "Did not stop container"
  docker container rm $DRAROK_CONTAINER_NAME && verbose "Did rm container" || echo "Did not rm container"
  docker run -d \
    -e TOKEN=$DRAROK_TOKEN \
    -e DRAROK_CRED_DIR=$DRAROK_CRED_DIR_CONTAINER
    --name $DRAROK_CONTAINER_NAME \
    -v $DRAROK_CRED_DIR_HOST:$DRAROK_CRED_DIR_CONTAINER \
    $DRAROK_IMAGE_NAME:$DRAROK_IMAGE_VERSION || err_exit "Starting container failed."
else
  echo "Did not stop or restart container."
fi
