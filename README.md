# Endava-DevOps-Challenge
DevOps Challenge from Endava

Requirements:
GitHub repo:
https://github.com/Endava-Sofia/endava-devops-challenge

Task description
1. Create public git repository
2. Choose a free Cloud Service Provider and register a free account with AWS, Azure, etc.
3. Automate provision of an Application stack running load balancer, web server and database of your choice, with the tools you like to use - Bash, Puppet, Chef, Ansible, Terraform, etc. Important - each of the services must run separately - on a virtual machine, container or as a service.
4. Include service monitoring in the automation
5. Automate service-fail-over, e.g. auto-restart of failing service
6. Document the steps in git history and commit your Infrastructure-as-a-code in the git repo
7. Send us link for the repository containing the finished solution
8. Present a working solution, e.g. not a powerpoint presentation, but a working demo

#Time Box
The task should be completed within 5 days.


------------------------------------------------------

Usage
Please follow the steps below marked with $ :

+ For convenience I will add the variables.tf as part of the repo;
+ You should change the region, add your credention file, aws configure, etc to test the module or only change the region to the default one;

+ $ terraform init
+ $ terraform plan -out tfplan
+ $ terraform apply "tfplan"

The solution consists Load balancer, EKS, MySQL, sample hello world app and appropriate roles for auth.

The solution don't contain any module only single resources and dependencies between them.

Once it's tested you can remove all the resources using:

+ $ terraform destroy