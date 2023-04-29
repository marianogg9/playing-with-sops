# Playing with SOPS

Here is a sample SOPS implementation using AWS KMS.

## Prerequisites

### KMS
- Create a KMS key.
    - Manually in console: AWS KMS > **Customer-managed** keys > **Create key** > **Symmetric** + **Encrypt and decrypt** options, **Next** > give it an alias, **Next** > select a **Key administrator**, **Next** > select a **Key user** (this step can be done later, after creating the IAM user), **Next** > **Finish**.
    - Via AWS CLI: TODO.
    - Terraform: TODO.

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
Remember to name it following the `creation_rules.path_regex` naming convention.
```bash
sops file.yaml
```

This will open a text editor in console (`vi` in my case) where you already have a template set of values to modify.
When you are done modifying and save the file, SOPS will automatically run the encryption process. If you then open the file, the encrypted values are in the following format:
`a-given-key: ENC[AES256_GCM,data:hash,iv:hash,tag:hash,type:str]` - including a data encryption key, the encrypted value and the original value type.

### Encrypt an existent file
If you already have a file you want to encrypt:
```bash
sops -e -i existing-file.yaml
```

This will encrypt the file in place. If you want to modify its content, run `sops existing-file.yaml` which will unencrypt it and open a text editor. When you are finished modifying, save it and SOPS will re encrypt its values and update both its `sops.lastmodified` and `sops.mac` attributes.

## Reference
[SOPS on GitHub](https://github.com/mozilla/sops)