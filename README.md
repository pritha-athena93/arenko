# Technical exercise 

Here you have some terraform which does not work! 

Please fix it and look at making changes for production best practices and reusability.
Feel free to add useful additional functionality where you feel it's appropriate to extend or improve the solution.
Please ensure you fully understand the changes you make, we will be diving deeper in a follow-up technical session and please list out any questions or assumptions you make.
Please send back your submission as a git repository or github link. 

# Assumptions -

1. S3 bucket for storing the tfstate is already created
2. ACM is created outside of this tf config
3. The region in use is enabled
4. The user applying the changes has admin access or permission to create the resources created through this tf
5. I added rds-db:connect to the ecs task role, although it doesn't need it right now, I enabled iam on the db, hence did it just to complete the config.

# Steps to apply -

1. Mention the var file location, ex - `terraform apply -var-file=environments/dev.tfvars.json` 
2. Add the relevant profile name - uncomment the profile line in main.tf
3. For different region, the tfstate also needs to be stored in different paths - `terraform init -backend-config="key=environments/dev/terraform.tfstate"`

# DR -

1. In prod we should do a pilot light or warm standby, but that requires more discussion on RTO.