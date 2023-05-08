# Playing with SOPS

Here is a sample SOPS implementation using AWS KMS.

Please have a look at the [blog article](https://blog.mariano.cloud/all-right-then-keep-your-secrets-in-git-with-sops) I wrote for a walkthrough.

1. [Prerequisites](#prerequisites)
    1. [KMS](#kms)
    2. [IAM](#iam)
    3. [Via Terraform](#via-terraform)
2. [SOPS](#sops)
    1. [Installing](#installing)
    2. [Add .sops.yaml](#add-sopsyaml-for-global-configuration)
    3. [Create a secrets file](#create-a-secrets-file)
    4. [Encrypt an existent file](#encrypt-an-existent-file)
    5. [Decrypt](#decrypt)
3. [Working example with Helmfile](#working-example-with-helmfile)
4. [Reference](#reference)

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
                "Resource": "arn:of:your:kms:key"
            }
        ]
    }
    ```

---

### Via Terraform
If you prefer doing it via TF instead of manually, I added a `/terraform/` directory. 

You will find all the instructions in there.

---

## SOPS

Configure your local AWS CLI to use the IAM user's (created before) credentials. See [this article](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html).

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

If you want to use different files for encrypted and unencrypted content, you can make use of `--output` flag to write the encrypt/decrypt results.

### Decrypt

There are different ways of doing it:
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

- To a different file:
    ```bash
    sops -d --output output-file.yaml file.yaml
    ```
    Will unencrypt and write its content to `output-file.yaml`.

## Working example with Helmfile
I added a sample walkthrough using Helmfile + Minikube in [this article](). The required files are in `helmfile/` dir.

## Reference
[SOPS on GitHub](https://github.com/mozilla/sops)