# 🌲 Forest IaC

This repository contains machine-readable specifications for the auxillilary services that [Forest](https://github.com/ChainSafe/forest) project running smoothly. The services include periodic uploads of network snapshots, and automated testing of Forest's capabilities.

## Sync Check

The sync check service is used as an extended CI to assert that recent commits to Forest's default branch are not breaking the sync with the Filecoin network. Due to the requirements of running a mainnet node, the service is not feasible to run in Github Actions.

An architectural diagram of the service can be found in [here](docs/sync-check-architecture.pdf).

## Collaborators
Feel free to contribute to the codebase by resolving any open issues, refactoring, adding new features, writing test cases, or any other way to make the project better and helpful to the community. Feel free to fork and send pull requests.

## Questions
Feel free to contact the team by creating an issue or raising a discussion [here](https://github.com/ChainSafe/forest/discussions) for more details on interacting with the infrastructure if the need arises during deployment.

## Past Snapshot Service

The snapshot service offered by the Forest team was transferred to the ChainSafe's infrastructure team for maintenance and further development. The previous implementation can be found [here](https://github.com/ChainSafe/forest-iac/pull/459).
