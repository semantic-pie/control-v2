#!/bin/bash

WORKDIR=$(pwd)
export GIT_TERMINAL_PROMPT=0

function usage() {
    cat <<USAGE

Usage:
    $0 [command] [options]

Commands:
    install      Install necessary services
    run          Run all services
    down         Stop all services
    help         Show usage information


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
# COMPONENTS PREPARE (SC-machine SC-web ProblemSover)

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
        if [ $2 = '--dev' ]; then
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
    ./domain/docker/build-image.sh
    ./recommendations/docker/build-image.sh
    ./streaming/docker/build-image.sh
    ./snoopy/docker/build-image.sh
    docker compose -f ./ui/docker/docker-compose.yaml build
    ;;

run)
    shift 1;
    while getopts "dh" opt; do
        case $opt in
        d) DETACHED=1 ;;
        h) run_usage  ;;
        \?) echo "Invalid option -$OPTARG" && run_usage
            exit 1
             ;;
        esac
    done
    shift $((OPTIND - 1))

    if [[ $DETACHED ]]; then
        echo "STARTING..."
        JWT_TOKEN_SECRET_KEY=9c1fff39-6863-4447-bd55-5eed0d6f2ecb9c1fff39-6863-4447-bd55-5eed0d6f2ecb docker compose -f ./db/docker-compose.yaml -f ./ui/docker-compose.yaml -f ./domain/docker/docker-compose.yaml -f ./streaming/docker/docker-compose.yaml -f ./snoopy/docker/docker-compose.yaml -f ./recommendations/docker/docker-compose.yaml up -d
    else 
        JWT_TOKEN_SECRET_KEY=9c1fff39-6863-4447-bd55-5eed0d6f2ecb9c1fff39-6863-4447-bd55-5eed0d6f2ecb docker compose -f ./db/docker-compose.yaml -f ./ui/docker/docker-compose.yaml -f ./domain/docker/docker-compose.yaml -f ./streaming/docker/docker-compose.yaml -f ./snoopy/docker/docker-compose.yaml -f ./recommendations/docker/docker-compose.yaml up
    fi
    ;;

stop)
    shift 1;
     docker compose -f ./db/docker-compose.yaml -f ./ui/docker/docker-compose.yaml -f ./domain/docker/docker-compose.yaml -f ./streaming/docker/docker-compose.yaml -f ./snoopy/docker/docker-compose.yaml -f ./recommendations/docker/docker-compose.yaml down 
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
