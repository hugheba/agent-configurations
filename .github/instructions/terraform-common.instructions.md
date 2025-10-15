# Terraform Common Rules

## Language & Format

- Use HCL (HashiCorp Configuration Language) exclusively
- Format code with `terraform fmt`
- Validate with `terraform validate`

## Deployment Environments

- **Local Workstation**: Use AWS_PROFILE for credentials
- **GitLab CI/CD**: Use OAuth credential roles

## Authentication Configuration

### Local Development

```hcl
provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

variable "aws_profile" {
  description = "AWS profile to use for authentication"
  type        = string
  default     = "default"
}
```

### GitLab CI/CD

```hcl
provider "aws" {
  region = var.aws_region
  # Credentials automatically loaded from GitLab OAuth roles
}
```

## Best Practices

- Use remote state backend (S3 + DynamoDB)
- Implement state locking
- Use workspaces for environment separation
- Pin provider versions
- Use data sources over hardcoded values
- Implement proper resource tagging

## File Structure

```
infrastructure/
├── main.tf          # Main configuration
├── variables.tf     # Input variables
├── outputs.tf       # Output values
├── versions.tf      # Provider versions
└── terraform.tfvars.example
```

## Required Variables

```hcl
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name for state organization"
  type        = string
}
```

## State Configuration

```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket"
    key            = "${var.project_name}/${var.environment}/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```
