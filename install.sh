#!/bin/bash
set -e
set -u
set -o pipefail

repo="logseq/logseq"
fedoraVersion=$(cat /etc/os-release | grep VERSION_ID | sed 's/VERSION_ID=//')
packageName="logseq-desktop"
buildContainerName="logseq-desktop-rpm"
outputDir="out"

function get_latest_version() {
    curl --silent "https://api.github.com/repos/$repo/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
}

function get_installed_version() {
    if [ -z "$(sudo dnf list installed | grep "$packageName")" ]
    then
        echo ""
    else
        sudo dnf list installed "$packageName" | awk '{print $2}' | tail -n 1 | sed 's/.......$//'
    fi
}

function ask_user_confirmation() {
    local hasResult=0
    local result=0
    while [ $hasResult -eq 0 ]; do
    read -p "$1 (y/n): " yn

    case $yn in
        [yY] ) result=1;
               hasResult=1;;
        [nN] ) result=0;
               hasResult=1;;
        * ) echo invalid response;;
    esac
    done
    echo $result
}

function get_missing_build_dependencies() {
    local podmanPackage="podman"
    local missing=""
    if [ -z "$(sudo dnf list installed | grep "$podmanPackage")" ]
    then
        missing+=" $podmanPackage"
    fi
    echo "$missing"
}

function ensure_build_dependencies_installed() {
    if [ ! -z $1 ]
    then
        echo "Installing missing dependencies $1"
        sudo dnf install -y $1
    fi
}

function ensure_proceed_with_build() {
    local installedVersion=$1
    local latestVersion=$2
    if [ -z "$installedVersion" ] && [ $(ask_user_confirmation "$packageName is not installed. Would you like to install the latest version?") -eq 0 ]
    then
        exit 0
    elif [ "$installedVersion" == "$latestVersion" ]
    then
        echo "$packageName is already up-to-date"
        exit 0
    fi
}

function ensure_max_user_namespaces_high_enough() {
    local namespaces=$(sudo sysctl -n user.max_user_namespaces)
    if [ "$namespaces" -le 0 ]
    then
        if [ $(ask_user_confirmation "Sysctl user.max_use_namespaces does not allowed to build logseq, would you like to increase it until the system is rebooted?") -eq 0 ]
        then
            exit 0
        fi
        sudo sysctl -w user.max_user_namespaces=1
    fi
}

function build() {
    echo "Performing build.."
    mkdir -p $outputDir
    arch=$(if [[ "$(uname -m)" == "aarch64" ]]; then echo "arm64v8"; else echo "amd64"; fi)
	podman build --build-arg=ARCH=$arch --build-arg=FEDORA_VERSION=$fedoraVersion -t "$buildContainerName:$1" .
	podman run -it --rm -v $(pwd)/$outputDir:/output:Z -e LOGSEQ_VERSION=$1 --name $buildContainerName "$buildContainerName:$1"
}

function install() {
    echo "Performing install..."
	sudo rpm -Uvh --force $outputDir/$packageName-$1-1.x86_64.rpm

    echo "Making sure sandbox has correct permissions..."
    sudo chmod 4755 /usr/lib/$packageName/chrome-sandbox
}

function clean_up() {
    echo "Performing Cleanup..."
	podman unshare rm -rf ./$outputDir
	podman rm -f $buildContainerName 2>/dev/null
    podman image prune --all 
    
    if [ $(ask_user_confirmation "Would you like to delete the build artefacts?") -eq 1 ]
    then
        rm -R -f $outputDir
    fi

    if [ ! -z "$1" ]
    then
        echo "Uninstalling build resources $1"
        sudo dnf remove -y $1
    fi
}

installedVersion=$(get_installed_version $packageName)
latestVersion=$(get_latest_version $repo)

ensure_proceed_with_build "$installedVersion" "$latestVersion"
ensure_max_user_namespaces_high_enough

missingDependencies=$(get_missing_build_dependencies)
ensure_build_dependencies_installed "$missingDependencies"
build "$latestVersion"
install "$latestVersion"
clean_up "$missingDependencies"
echo "$packageName-$latestVersion successfully installed"
