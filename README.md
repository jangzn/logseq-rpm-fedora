## About The Project

This repository provides a small script that allows you to install / update the [Logseq](https://github.com/logseq/logseq) desktop client from a self-built RPM package on Fedora. It uses a [Podman](https://github.com/containers/podman) container to build the RPM package. The script installs podman if it is not installed yet - and will remove it again after the build in case it was not installed.


## Usage

Clone this repository:
`git clone https://github.com/jangzn/logseq-rpm-fedora.git`

Make the script executable:
`chmod +x ./logseq-rpm-fedora/install.sh`

Run the script and get yourself a coffee or two:
`./logseq-rpm-fedora/install.sh`


## Acknowledgments
* [Logseq](https://github.com/logseq/logseq)
* [Podman](https://github.com/containers/podman)