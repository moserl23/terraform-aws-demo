# Terraform on AWS Learning Demo

Terraform lets you describe the AWS infrastructure you want in code. Terraform then compares that desired configuration with its state and the real AWS environment and determines what needs to change.

```text
Terraform configuration (.tf)
            |
            v
      Terraform plan
            |
            v
Terraform state <-> Real AWS infrastructure
            |
            v
      terraform apply
```

Terraform is not AWS, and it does not provide free infrastructure. It uses your existing authenticated AWS account through the AWS provider:

```text
Terraform
    |
    v
AWS provider
    |
    v
AWS API
    |
    v
AWS resources
```

This repository is a compact, safe, hands-on Terraform demo. It uses S3 as the main example because S3 is easy to inspect, inexpensive for tiny demos, and good for learning how Terraform connects configuration, state, and real cloud resources.

## What This Creates

This demo creates:

- one private S3 bucket
- one S3 public access block for that bucket
- one S3 bucket versioning configuration, disabled by default
- one tiny text object named `hello-terraform.txt`
- tags on the resources so they are easy to identify

It does not create NAT Gateways, databases, load balancers, EC2 instances, or other always-on infrastructure. Even so, AWS resources can be billable. Review every Terraform plan before applying it, and destroy the demo when you are finished.

## Repository Layout

```text
.
|-- README.md
|-- main.tf
|-- providers.tf
|-- variables.tf
|-- outputs.tf
|-- terraform.tfvars.example
|-- .terraform.lock.hcl
`-- .gitignore
```

The files have separate jobs:

- `providers.tf` declares Terraform and AWS provider requirements.
- `variables.tf` defines inputs you can customize.
- `main.tf` contains the data sources, locals, and AWS resources.
- `outputs.tf` prints useful values after apply.
- `terraform.tfvars.example` shows optional local overrides.
- `.terraform.lock.hcl` pins provider checksums and should usually be committed.
- `.gitignore` keeps local state, credentials-like values, and provider caches out of Git.

## Concepts You Will See

This small project demonstrates:

- providers and provider versions
- the AWS provider
- resources
- variables and validation
- outputs
- locals
- references between resources
- implicit dependencies
- data sources
- tags
- Terraform state
- `.terraform.lock.hcl`
- `terraform init`, `fmt`, `validate`, `plan`, `apply`, and `destroy`
- `terraform state list`
- idempotency
- declarative Infrastructure as Code
- the difference between desired configuration, Terraform state, and actual AWS infrastructure

## Prerequisites

You need Terraform, the AWS CLI, and AWS credentials already configured on your machine.

Check Terraform:

```bash
terraform --version
```

This confirms Terraform is installed and shows the version that will run this configuration.

Check the AWS CLI:

```bash
aws --version
```

This confirms the AWS CLI is installed.

Check which AWS account you are authenticated against:

```bash
aws sts get-caller-identity
```

This is an important safety check. Terraform will create resources in the AWS account returned by this command.

## Configure The Demo

The defaults are ready to use:

- `aws_region = "eu-north-1"`
- `project_name = "terraform-aws-demo"`
- `environment = "dev"`
- `enable_bucket_versioning = false`

To customize them locally, copy the example file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Then edit `terraform.tfvars`. That file is ignored by Git because local variable files can contain user-specific or sensitive values.

The bucket name is built in `locals`:

```hcl
bucket_name = "${local.name_prefix}-${data.aws_caller_identity.current.account_id}-${var.aws_region}"
```

S3 bucket names must be globally unique. Including your AWS account ID and region makes collisions unlikely while keeping the name understandable.

Common tags are also built with `locals`:

```hcl
common_tags = merge(
  {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Purpose     = "Terraform AWS learning demo"
  },
  var.extra_tags
)
```

This keeps tags consistent across resources.

## Initialize

Run:

```bash
terraform init
```

This downloads the AWS provider into the local `.terraform/` directory and creates or updates `.terraform.lock.hcl`.

The `.terraform/` directory is local machine cache and should not be committed. The `.terraform.lock.hcl` file should generally be committed because it records the selected provider version and checksums, making future installs more reproducible.

## Format And Validate

Run:

```bash
terraform fmt
terraform validate
```

`terraform fmt` rewrites Terraform files into the standard style.

`terraform validate` checks that the configuration is syntactically valid and internally consistent. It does not create AWS resources.

## Preview Changes

Run:

```bash
terraform plan
```

Terraform compares:

- your `.tf` files, which describe what you want
- Terraform state, which records what Terraform believes it manages
- real AWS infrastructure, which is what actually exists

In the plan output, watch for these symbols:

```text
+ create
~ update
- destroy
```

Terraform will also summarize the plan:

```text
Plan: X to add, Y to change, Z to destroy.
```

For your first run, you should expect several resources to be created. If you see anything surprising, stop and inspect the plan before applying.

## Apply

Run:

```bash
terraform apply
```

Terraform shows the plan again and waits for confirmation. Nothing is changed until you type:

```text
yes
```

After apply, Terraform writes local state to `terraform.tfstate`. State can contain sensitive information and should not be committed to Git.

## Inspect The Result

Print the outputs:

```bash
terraform output
```

You should see values such as:

- `aws_account_id`
- `aws_region`
- `bucket_name`
- `bucket_arn`
- `bucket_region`
- `bucket_versioning_status`
- `demo_object_s3_uri`

List the resources Terraform tracks in state:

```bash
terraform state list
```

You should see addresses similar to:

```text
aws_s3_bucket.demo
aws_s3_bucket_public_access_block.demo
aws_s3_bucket_versioning.demo
aws_s3_object.hello
data.aws_caller_identity.current
data.aws_region.current
```

Confirm the bucket exists with the AWS CLI:

```bash
aws s3 ls
```

You can also inspect the demo object:

```bash
aws s3 cp "s3://$(terraform output -raw bucket_name)/hello-terraform.txt" -
```

## Idempotency Experiment

Immediately run:

```bash
terraform plan
```

Terraform should report:

```text
No changes.
```

This is idempotency. Applying the same desired configuration again should not keep creating new infrastructure. Terraform sees that the configuration, state, and AWS already match.

## Modify Infrastructure

Make a small tag-only change in `terraform.tfvars`:

```hcl
extra_tags = {
  Owner  = "your-name"
  Lesson = "updated-tags"
}
```

Then run:

```bash
terraform plan
terraform apply
```

The plan should show `~ update` for tag changes. The `~` symbol means Terraform can update an existing resource in place.

You can also test versioning:

```hcl
enable_bucket_versioning = true
```

Then run `terraform plan` and read the change carefully. S3 versioning can retain older object versions, which is useful in real systems but can make cleanup more detailed if you manually add more objects later.

## Drift Experiment

Drift happens when real AWS infrastructure changes outside Terraform.

A safe drift experiment is to add or edit a tag on the demo bucket in the AWS console, then run:

```bash
terraform plan
```

Terraform should notice that the real bucket no longer matches the desired tags in your `.tf` files. Do not manually delete the bucket for this experiment; that makes cleanup less beginner-friendly.

## Destroy

When you are finished, remove the demo resources:

```bash
terraform destroy
```

Terraform will show a destroy plan and wait for confirmation. It normally removes only resources it manages in state, not unrelated manually-created AWS resources.

This demo intentionally does not set `force_destroy = true` on the S3 bucket. That protects you from accidentally deleting a bucket that contains unexpected objects. If you add files manually, delete those files before destroying the bucket.

## Terraform State

Terraform state is the bridge between code and real infrastructure:

```text
main.tf
    =
what I WANT

terraform.tfstate
    =
what Terraform believes it manages and the corresponding real resource IDs

AWS
    =
what ACTUALLY exists
```

State matters because AWS resources have real IDs. Terraform needs to remember that `aws_s3_bucket.demo` in your code corresponds to a specific S3 bucket in AWS.

Do not casually edit `terraform.tfstate` by hand. If state and AWS disagree, Terraform may plan changes you did not expect. Use Terraform commands such as `terraform state list`, `terraform state show`, `terraform import`, or `terraform state rm` when you are intentionally working with state.

Real teams usually store state remotely, often in an S3 backend with locking. This beginner demo uses local state so you can see the moving parts without adding backend configuration yet.

## Desired Configuration, State, And Reality

It helps to keep these three ideas separate:

- Desired configuration: the `.tf` files in this repository.
- Terraform state: Terraform's record of the resources it manages.
- Actual infrastructure: the resources that exist in AWS right now.

`terraform plan` is Terraform asking: "What changes would make actual infrastructure match the desired configuration, using state as my map?"

## Git Hygiene

This repository ignores:

- `.terraform/`
- `*.tfstate`
- `*.tfstate.*`
- `*.tfvars`
- crash logs
- local override files

It keeps:

- `.terraform.lock.hcl`
- `terraform.tfvars.example`

Never commit AWS credentials, secrets, or local state. Terraform state can contain sensitive values even when this particular demo is intentionally simple.

## Ideas To Extend This Demo

Beginner:

- add another S3 object
- add another tag through `extra_tags`
- enable bucket versioning and inspect object versions
- compare a manually-created S3 bucket with a Terraform-created bucket

Intermediate:

- add an S3 lifecycle rule
- use `for_each` to create multiple demo objects
- create a small reusable S3 module
- move state to a remote S3 backend
- add GitHub Actions to run `terraform fmt`, `validate`, and `plan`

Advanced:

- introduce IAM in a careful, least-privilege way
- explore Terraform with Databricks using the Databricks provider
- add policy checks with a tool such as Checkov or tfsec
- practice importing an existing resource into Terraform state
