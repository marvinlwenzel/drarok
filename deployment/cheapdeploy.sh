#!/bin/bash

# Default configuration

SHOULD_SOURCE_ENVFILE=TRUE
FORCE_RESTART=TRUE
VERBOSE=FALSE
RECURSIVE_OPT=""
ATTACHMENT="-d"
# Helping functions

verbose () {
  [[ $VERBOSE == TRUE ]] && echo $@
}

err_exit () {
  echo "$@" >&2
  echo "Abort." >&2
  exit 1
}


function check_madatory_parameters_or_fail() {

  # Check for required options being set
  # Maybe you wanna use this when working in the script
  # grep -o '\$[A-Z_][A-Z_]*' cheapdeploy.sh  | sort | uniq | grep -o "[A-Z_]*"
  # grep -o '\$DRAROK[A-Z_]*' cheapdeploy.sh  | sort | uniq | grep -o "[A-Z_]*"
  # use this to make the output one like
  # grep -o '\$[A-Z_][A-Z_]*' cheapdeploy.sh  | sort | uniq | grep -o "[A-Z_]*" | sed ':a;N;$!ba;s/\n/ /g'
  # grep -o '\$DRAROK[A-Z_]*' cheapdeploy.sh  | sort | uniq | grep -o "[A-Z_]*" | sed ':a;N;$!ba;s/\n/ /g'

  for mandatory_variable_name in DRAROK_CONTAINER_NAME DRAROK_CRED_DIR_CONTAINER \
    DRAROK_CRED_DIR_HOST DRAROK_IMAGE_NAME DRAROK_TOKEN DRAROK_WORKDIR
  do

    # https://unix.stackexchange.com/questions/41292/variable-substitution-with-an-exclamation-mark-in-bash
    # Inderect varibale addressing - bash pointers. Lit af
    # When the variable named as the content of the variable mandatory_variable_name is empty or not set
    if [[ ! -z ${!mandatory_variable_name} ]]
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
  [[ $MANDATORY_VARIABLE_MISSING == TRUE ]] && err_exit "Mandatory variable(s) missing."

}

function source_env_files_or_fail() {
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

  # If something should have been sourced, but nothing was sourced: fail.

  if [[ $SHOULD_SOURCE_ENVFILE == "TRUE" && ! $AT_LEAST_ONE_ENVFILE_WAS_SOURCED == "TRUE" ]]
  then
      echo "Did not find any environment variables. If this is intended, run again with --no-envfiles" >&2
  fi
}

function container_exists() {
  docker inspect -f '{{.State.Running}}' $DRAROK_CONTAINER_NAME > /dev/null 2>&1 && echo TRUE || echo FALSE
}

function container_runs() {
  [[ $(docker inspect -f '{{.State.Running}}' $DRAROK_CONTAINER_NAME 2>/dev/null) == true ]] && echo TRUE || echo FALSE
}


function stop_container() {
  [[ $(container_exists) == FALSE ]] && err_exit "Container $DRAROK_CONTAINER_NAME does not exist."
  docker stop $DRAROK_CONTAINER_NAME || echo "Could not stop container $DRAROK_CONTAINER_NAME" >&2
  [[ $(container_runs) == TRUE ]] && err_exit "Container $DRAROK_CONTAINER_NAME still runs."
  echo "No container $DRAROK_CONTAINER_NAME running."
  exit 0
}

function start_container() {
  [[ $(container_exists) == FALSE ]] && err_exit "Container $DRAROK_CONTAINER_NAME does not exist."
  [[ $(container_runs) == TRUE ]] && err_exit "Container $DRAROK_CONTAINER_NAME already runs."
  docker start $DRAROK_CONTAINER_NAME || err_exit "Failed starting $DRAROK_CONTAINER_NAME"
  echo "Started container $DRAROK_CONTAINER_NAME"
  exit 0
}

function restart_container() {
  did="Started"
  [[ $(container_exists) == FALSE ]] && err_exit "Container $DRAROK_CONTAINER_NAME does not exist."
  if [[ $(container_runs) == TRUE ]]
  then
    docker stop $DRAROK_CONTAINER_NAME || err_exit "Could not stop running container $DRAROK_CONTAINER_NAME."
    did="Restarted"
  fi
  docker start $DRAROK_CONTAINER_NAME || err_exit "Failed starting $DRAROK_CONTAINER_NAME"
  echo "$did container $DRAROK_CONTAINER_NAME"
}

function cd_working_dir() {
  # If DRAROK_WORKDIR exists, go in there

  [[ -d $DRAROK_WORKDIR ]] || err_exit "DRAROK_WORKDIR $DRAROK_WORKDIR does not exist."
  cd $DRAROK_WORKDIR

  # No repository, no deployment

  git status >/dev/null 2>&1 || err_exit "There appears to be no git repository in here."
}


function update_repo() {
  if [[ -z $BRANCH ]]
  then
    git pull || err_exit "Git pull failed."
  else
    git pull origin $BRANCH || err_exit "Git pull failed."
    git checkout $BRANCH || err_exit "Git checkout failed."
  fi
}

function build_image() {
  # Build docker image locally

  GIT_COMMIT_SHA_SHORT=$(git rev-parse HEAD | head -c12)
  docker build . -t $DRAROK_IMAGE_NAME:$GIT_COMMIT_SHA_SHORT -t $DRAROK_IMAGE_NAME:latest || err_exit "Could not build docker image"
  echo "Built commit: $GIT_COMMIT_SHA_SHORT"
}


function deploy_new_image() {
  docker stop $DRAROK_CONTAINER_NAME && verbose "Stopped container $DRAROK_CONTAINER_NAME" || echo "Did not stop container $DRAROK_CONTAINER_NAME"
  docker container rm $DRAROK_CONTAINER_NAME && verbose "Removed container $DRAROK_CONTAINER_NAME" || echo "Did not remove container $DRAROK_CONTAINER_NAME"
  docker run $DETACH \
    -e DRAROK_TOKEN=$DRAROK_TOKEN \
    -e DRAROK_CRED_DIR=$DRAROK_CRED_DIR_CONTAINER \
    --name $DRAROK_CONTAINER_NAME \
    -v $DRAROK_CRED_DIR_HOST:$DRAROK_CRED_DIR_CONTAINER \
    $DRAROK_IMAGE_NAME:$GIT_COMMIT_SHA_SHORT || err_exit "Starting container failed."
  echo "Started new container on image $DRAROK_IMAGE_NAME:$GIT_COMMIT_SHA_SHORT"
}

function die_if_command_set() {
  [[ ! -z $COMMAND ]] && err_exit 'Command given multiple times. Only use start, restart or stop once.'
}

# Parse arguments

for i in "$@"
do
case $i in

    # see https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash

    # -e=*|--extension=*)
    # EXTENSION="${i#*=}""
    # shift # past argument=value
    # ;;
    start)
      die_if_command_set
      COMMAND=START
      shift
    ;;
    stop)
      die_if_command_set
      COMMAND=STOP
      shift
    ;;
    restart)
      die_if_command_set
      COMMAND=RESTART
      shift
    ;;
    build)
      die_if_command_set
      COMMAND=BUILD
      shift
    ;;
    redeploy)
      die_if_command_set
      COMMAND=REDEPLOY
      shift
    ;;
    --no-envfiles)
      SHOULD_SOURCE_ENVFILE=FALSE
      RECURSIVE_OPT="$RECURSIVE_OPT $i"
      shift
    ;;
    -v|--verbose)
      VERBOSE=TRUE
      RECURSIVE_OPT="$RECURSIVE_OPT $i"
      shift
    ;;
    -c=*|--cred-dir-host=*)
      DRAROK_CRED_DIR_HOST="${i#*=}"
      RECURSIVE_OPT="$RECURSIVE_OPT $i"
      shift
    ;;
    --branch=*)
      BRANCH="${i#*=}"
      RECURSIVE_OPT="$RECURSIVE_OPT $i"
      shift
    ;;
    --auto-tagging)
      AUTO_TAGGING=TRUE
      RECURSIVE_OPT="$RECURSIVE_OPT $i"
      shift
    ;;
    --no-auto-tagging)
      AUTO_TAGGING=FALSE
      RECURSIVE_OPT="$RECURSIVE_OPT $i"
      shift
    ;;
    --attach)
      ATTACHMENT="-it"
      RECURSIVE_OPT="$RECURSIVE_OPT $i"
      shift
    ;;
    -h|--help)
    help="$0 [start|restart|stop|build|redeploy] <OPTIONS>

-h|--help           Show this.

--no-envfiles       Do not source any .env files. By default, a file named .env is
                    sourced, otherwise all files matching *.env are sourced. If none
                    are found, exit 1.

-r=<REP>|--repository=<REP>
                    Set the git repository to <REP>. Does NOT imply
                    --clone-if-missing.

-c=<DIR>>|--cred-dir-host=<DIR>
                    Sets the directory that contains the credntial files on the
                    host. Must be set.

-v|--verbose        MIGHT LOG CREDENTIALS. CARE.

--attach            Attach to container after starting.
"
      echo "$help"
      exit 0
    ;;
    *)
      err_exit "Unknown option $i"
    ;;
esac
done


source_env_files_or_fail

# Die if DRAROK_CONTAINER_NAME is missing
[[ -z $DRAROK_CONTAINER_NAME ]] && err_exit "Must specify DRAROK_CONTAINER_NAME."


case $COMMAND in
  STOP)
    stop_container
  ;;
  START)
    start_container
  ;;
  RESTART)
    restart_container
  ;;
  BUILD)
    check_madatory_parameters_or_fail
    cd_working_dir
    update_repo
    build_image
  ;;
  REDEPLOY)
    check_madatory_parameters_or_fail
    cd_working_dir
    update_repo
    build_image
    deploy_new_image
  ;;
  *)
    err_exit "Must specify valid command. Consult $0 --help"
  ;;
esac
