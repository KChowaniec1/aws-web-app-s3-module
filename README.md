# Terraform Module for Web App Hosted by S3 Bucket on AWS

This Terraform module deploys a web application to AWS.
It uses S3, CloudFront, WAF, and Route53 services. 
It hosts all static assets found in the directory on S3 and adds them to a CloudFront distribution.
Then all traffic to the domain get routed to CloudFront.

## Getting started

### How to use

1.  Create the following main.tf in your project root directory. Replace the `aws.profile` and `aws-static-website.domain_name`. Region defaults to `us-east-1` due to ACM Certificate Manager requirements.

    ```terraform
    # main.tf

    provider "aws" {
        region  = "us-east-1"
        profile = "example"
    }

    module "aws-static-website" {
        source        = "https://github.com/KChowaniec1/aws-web-app-s3-module"
        domain_name   = "example.com"
    }
    ```

1.  Initialize and run terraform apply

	```terraform 
	terraform init

    terraform plan    #=> generates an execution plan.
    terraform apply   #=> builds infrastructure on AWS.
   
    ```

## Variables

Required:

- **app_source_dir**

      type: string
      description: The distribution directory to serve via static asset host

- **domain_name**

      type: string
      description: The primary domain name.
	  
- **website_bucket_name**

      type: string
      description: The bucket name to store static assets

Optional:

- **alias_domains**

      type: list(string)
      description: The other alias domain names (www.example.com).
      default: []

- **env**

      type: string
      description: The current environment
      default: dev



