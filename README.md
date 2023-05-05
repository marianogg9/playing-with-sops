# Playing with SOPS

Here is a sample SOPS implementation using AWS KMS.

Please have a look at the [blog article]() I wrote for better insights.

## Prerequisites

### KMS
Create a KMS key.

- Manually in console: 
    
    1. Access AWS KMS. 
    2. Go to **Customer-managed** keys and click on **Create key**.
    4. Select **Symmetric** + **Encrypt and decrypt** options, then **Next**.
    5. Give it an alias and **Next**.
    6. Select a **Key administrator** and **Next**.
    7. Select a **Key user** (this step can be done later, after creating the IAM user), **Next**.
    8. **Finish**.

### IAM
- Create a new IAM user (or a role to assume).
- Attach a KMS policy:
    ```json
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "VisualEditor0",
                "Effect": "Allow",
                "Action": [
                    "kms:Decrypt",
                    "kms:Encrypt",
                    "kms:DescribeKey"
                ],
                "Resource": "arn:of:your:ksm:key"
            }
        ]
    }
    ```

---

### Via Terraform
If you prefer doing it via TF instead of manually, I added a `/terraform/` directory. 

There is a caveat though. Currently, [a bug in AWS provider](https://github.com/hashicorp/terraform-provider-aws/issues/27611) is blocking Terraform to fetch back `TRUE` status of the KMS policy apply.
Feel free to upvote it.

Also you will need a S3 bucket for tfstate and a DynamoDB table for tfstate lock.

If you don't have those:
```bash
aws s3api create-bucket --create-bucket-configuration LocationConstraint="your_region" --bucket your_bucket_name

aws dynamodb create-table --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 --table-name your_table_name
```

Now you can use the above created for the next steps.

```bash
cd terraform
```

You will need to set the following values, in `locals.tf`:
```yaml
locals {
    admin_user  = "your_admin_user"
    sops_user   = "sops-user"
}
```

Then in `terraform-backend.tf`:
```yaml
terraform {
  backend "s3" {
    bucket         = "your_bucket"
    key            = "your_bucket_tfstate_file"
    region         = "your_region"
    dynamodb_table = "your_dynamodb_table"
  }
}
```

To deploy:
```bash
terraform init
terraform apply
```

Sadly it will timeout in 10 min (default) with:

`Error: attaching KMS Key policy (hash): updating policy: waiting for completion: timeout while waiting for state to become 'TRUE' (last state: 'FALSE', timeout: 10m0s)`

But the policy would be applied.

---

## SOPS

### Installing
```bash
brew install sops
```

### Add .sops.yaml for global configuration
And add the following:
```bash
creation_rules:
  - path_regex: \.yaml$
    kms: 'arn:of:your:kms:key'
```

### Create a secrets file
Remember the `creation_rules.path_regex` naming convention.
```bash
sops file.yaml
```

This will open a text editor in console (`vi` in my case) where you will already have a template set of values to modify:
```yaml
hello: Welcome to SOPS! Edit this file as you please!
example_key: example_values
# Example comment
example_array:
    - example_value1
    - example_value2
example_number: 1234.56789
example_booleans:
    - true
    - false
```

When you are done modifying and save the file, SOPS will automatically run the encryption process. If you then open the file (`file.yaml`), the encrypted values are in the following format:

```bash
a-given-key: ENC[AES256_GCM,data:hash,iv:hash,tag:hash,type:str]
```

Including a data encryption key, the encrypted value and the original value type.

### Encrypt an existent file
If you already have a file you want to encrypt:
```bash
sops -e -i existing-file.yaml
```

This will encrypt the file in place. 

If you want to modify its content, run 

`sops existing-file.yaml` 

Which will unencrypt it and open a text editor.

When you are finished modifying, save it and SOPS will re encrypt its values and update both its `sops.lastmodified` and `sops.mac` attributes.

### Decrypt

There are two ways of doing it:
- In place:
    ```bash
    sops -i -d file.yaml
    ```
    Will unencrypt and write output back to the same file instead of stdout.

- In stdout:
    ```bash
    sops -d file.yaml
    ```
    Will unencrypt its content and write to stdout.

## Reference
[SOPS on GitHub](https://github.com/mozilla/sops)