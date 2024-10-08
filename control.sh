#!/bin/bash

set -a            
source .env
set +a

WORKDIR=$(pwd)
export GIT_TERMINAL_PROMPT=0

function usage() {
    cat <<USAGE

Usage:
    $0 [command] [options]

Commands:
    install             Install necessary services
    build   [service]   Build all services (or provided)
    rebuild [service]   Rebuild and run provided service (it is convenient when work with a specific service)
    run     [d]         Run all services (d - detach mode)
    stop                Stop all services
    help                Show usage information


USAGE
    exit 1
}

function run_usage() {
    cat <<USAGE

Usage:
    $0 run [-d]

Options:
    d      Detached run. Run docker containers in detached mod.

USAGE
    exit 1
}



# ==============================================
# COMPONENTS PREPARE

# clone / pull any component
function prepare_component() {
    REPO=$1
    NAME=$2
    BRANCH=$3
    echo -e "\033[1m[$NAME]\033[0m":
    if [ -e "$NAME" ]; then
        cd $NAME   
        git pull
    else
        if [ "$BRANCH" ]; then 
            git clone --branch "$BRANCH" "$REPO" "$NAME"
        else 
        git clone "$REPO" "$NAME"
        fi
    fi
    cd $WORKDIR
}


# ==============================================
# UTILITIES 

# check if repo ever exist and clone
function clone_git_repo() {
    REPO=$1
    NAME=$2
    if git ls-remote --exit-code $REPO > /dev/null 2>&1; then
        # if repo exist - clone
        git clone --depth=1 "$REPO" "$NAME"
    else
        echo "Repo: [$REPO] not exist."
        exit 1
    fi
}


# ==============================================
# COMMAND SWITCHER

case $1 in
install)
    if [ "$2" == "--dev" ]; then
        prepare_component git@github.com:semantic-pie/pie-tunes-domain domain
        prepare_component git@github.com:semantic-pie/pie-tunes-streaming streaming
        prepare_component git@github.com:semantic-pie/pie-tunes-ui-vite ui
        prepare_component git@github.com:semantic-pie/pie-tunes-snoopy snoopy
        prepare_component git@github.com:semantic-pie/pie-tunes-recommendation-service recommendations
    else
        prepare_component https://github.com/semantic-pie/pie-tunes-domain domain
        prepare_component https://github.com/semantic-pie/pie-tunes-streaming streaming
        prepare_component https://github.com/semantic-pie/pie-tunes-ui-vite ui
        prepare_component https://github.com/semantic-pie/pie-tunes-snoopy snoopy
        prepare_component https://github.com/semantic-pie/pie-tunes-recommendation-service recommendations
    fi
    ;;

build)
    shift 1;
    if [ -z "$1" ]; then
        ./domain/docker/build-image.sh
        ./recommendations/docker/build-image.sh
        ./streaming/docker/build-image.sh
        ./snoopy/docker/build-image.sh
        docker compose -f ./ui/docker/docker-compose.yaml build   
    else
        echo "[${1}] Start building..."
        eval "./${1}/docker/build-image.sh" && echo "[${1}]"
    fi
    ;;

run)
    shift 1;
    case $1 in
        d) DETACHED=1 ;;
        h) run_usage  ;;
        \?) echo "Invalid option -$OPTARG" && run_usage
            exit 1
             ;;
    esac

    if ! $DETACHED ; then
        echo "STARTING..."
        docker compose -f ./db/docker-compose.yaml -f ./ui/docker/docker-compose.yaml -f ./domain/docker/docker-compose.yaml -f ./streaming/docker/docker-compose.yaml -f ./snoopy/docker/docker-compose.yaml -f ./recommendations/docker/docker-compose.yaml up -d
    else 
        docker compose -f ./db/docker-compose.yaml -f ./ui/docker/docker-compose.yaml -f ./domain/docker/docker-compose.yaml -f ./streaming/docker/docker-compose.yaml -f ./snoopy/docker/docker-compose.yaml -f ./recommendations/docker/docker-compose.yaml up
    fi
    ;;

stop)
    shift 1;
    docker compose -f ./db/docker-compose.yaml -f ./ui/docker/docker-compose.yaml -f ./domain/docker/docker-compose.yaml -f ./streaming/docker/docker-compose.yaml -f ./snoopy/docker/docker-compose.yaml -f ./recommendations/docker/docker-compose.yaml down 
    echo "[DELETED]"
    ;;

rebuild)
    shift 1;
    if [ -z "$1" ]; then
       echo "Provide service name. ./control.sh rebuild [domain|recommendations|snoopy|streamin|ui]"
    else
        docker compose -f ./db/docker-compose.yaml -f ./ui/docker/docker-compose.yaml -f ./domain/docker/docker-compose.yaml -f ./streaming/docker/docker-compose.yaml -f ./snoopy/docker/docker-compose.yaml -f ./recommendations/docker/docker-compose.yaml down
        echo "[${1}] Start building..."
        eval "./${1}/docker/build-image.sh" && echo "[${1}]"
        docker compose -f ./db/docker-compose.yaml -f ./ui/docker/docker-compose.yaml -f ./domain/docker/docker-compose.yaml -f ./streaming/docker/docker-compose.yaml -f ./snoopy/docker/docker-compose.yaml -f ./recommendations/docker/docker-compose.yaml up -d
    fi
    ;;

restart)
    shift 1;
    docker compose -f ./db/docker-compose.yaml -f ./ui/docker/docker-compose.yaml -f ./domain/docker/docker-compose.yaml -f ./streaming/docker/docker-compose.yaml -f ./snoopy/docker/docker-compose.yaml -f ./recommendations/docker/docker-compose.yaml down 
    docker compose -f ./db/docker-compose.yaml -f ./ui/docker/docker-compose.yaml -f ./domain/docker/docker-compose.yaml -f ./streaming/docker/docker-compose.yaml -f ./snoopy/docker/docker-compose.yaml -f ./recommendations/docker/docker-compose.yaml up -d
    echo "[RESTARTED]"
    ;;

--help)
    usage
    ;;
help)
    usage
    ;;
-h)
    usage
    ;;

# All invalid commands will invoke usage page
*)
    usage
    ;;
esac
