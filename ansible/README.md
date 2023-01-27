# Running Forest In DigitalOcean

## Architectural Implementation

The flow goes from Terraform for provisioning of the servers and Anisble to run all neccessary installations including forest.

## Requiremnts 
- RAM: 32GB
- VCPU: 8
- Startup Disk Size: 100 GB
- Expected Total Disk Size: >500 GB

N/B: It's worth to note that some of the naming conventions can be changed to suit your deployment needs. 

To test out the implementation, just run `make plan` and `make apply` in the appropiate directory.

## Collaborators
- [YOUR NAME HERE] - Feel free to contribute to the codebase by resolving any open issues, refactoring, adding new features, writing test cases or any other way to make the project better and helpful to the community. Feel free to fork and send pull requests.

## Questions
Feel free to reach out to the BlockOps team for more details on how to interact with the infrastructure if the need arises while in deployment. 