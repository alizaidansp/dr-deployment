# ECR Module Deployment Notes

## Jenkins vs Local Deployment Differences

### Docker Privileges(in ECR Module,)
- **Jenkins Deployment**: Does not require `sudo` permissions as the app is pulled automatically
- **Local Deployment**: Requires `sudo` permissions for Docker commands

### File Path Configuration

#### Path Differences(main.tf)
- **Local Deployment**: 
  ```terraform
  dockerfile_path = "${path.module}/../waf-lamp-repo" # Correct path to directory
  ```

- **Jenkins Deployment**: 
  ```terraform
  dockerfile_path = "${path.module}/waf-lamp-repo" # Correct path to directory
  ```

### Implementation Details

The ECR module configures:
1. An ECR repository in the primary region with image scanning on push
2. Cross-region replication to a secondary region
3. Docker image build and push processes

### Module Call Example

```terraform
module "ecr" {
  source = "./modules/ecr"
  repository_name = var.repository_name
  secondary_region = var.secondary_region # us-east-1
  account_id = var.account_id
  primary_region = var.primary_region
  
  # Choose the appropriate path based on deployment method:
  # dockerfile_path = "${path.module}/../waf-lamp-repo" # Local Deployment
  dockerfile_path = "${path.module}/waf-lamp-repo" # Jenkins Deployment
}
```

### Provisioner Configuration

The module includes two provisioner configurations:
- One for Jenkins deployment (commented out in the provided code)
- One for local deployment with required `sudo` privileges
- Within the ECR Module

Remember to uncomment the appropriate provisioner and configure the correct path depending on your deployment method.

## Resource Tags

The ECR repository is tagged with:
- Name: "lamp-app"
- Environment: "DisasterRecovery"
- Project: "LaravelApp"