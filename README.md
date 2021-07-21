# Terraform Module for Web App Hosted by S3 Bucket on AWS

This Terraform module deploys a web application to AWS.
It uses S3, CloudFront, ACM, WAF, and Route53 services. 
All static assets provided in the app source directory are hosted on S3 and then added to a CloudFront distribution.
A SSL certificate is created for the domain name and all traffic to the domain gets routed to CloudFront via a Route 53 entry.
The CloudFront distribution has a web application firewall (WAF) associated with it to provide rule-based security.

## Design Considerations
CloudFront was chosen as a CDN for the static assets stored in the S3 bucket due to its ability to cache contents and serve over https (more secure) with SSL certificates provisioned by ACM. 
The origin S3 bucket uses server-side encryption to help protect contents as they are uploaded. Versioning is also enabled in case older versions of content are needed. CORS headers are allowed/enabled to support calling external sites.
Multiple subdomains/alias domains are accepted as Route53 can support redirecting these domains to the same CloudFront distribution. 
The WAF service can support many more types of rules than the ones provided in this module. These additonal types of custom rules can be added in the future. 

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
        source        		= "https://github.com/KChowaniec1/aws-web-app-s3-module"
        domain_name   		= "example.com"
		website_bucket_name = "example"
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
      description: The source directory to serve static assets

- **domain_name**

      type: string
      description: The primary domain name.
	  
- **website_bucket_name**

      type: string
      description: The bucket name to store static assets in S3

Optional:

- **alias_domains**

      type: list(string)
      description: The other alias domain names (www.example.com).
      default: []

- **managed_rules**

      type: list(object)
      description: The list of AWS managed rules to apply to the WAF
      default: [{
      name            = "AWSManagedRulesCommonRuleSet",
      priority        = 10
      override_action = "none"
      excluded_rules  = []
	  }]

- **ip_sets_rules**

      type: list(object)
      description: The list of custom IP rules to apply to the WAF
      default: []


