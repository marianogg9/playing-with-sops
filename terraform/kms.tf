resource "aws_kms_key" "kms_key" {
  description             = "KMS key to be used by SOPS encrypt/decrypt"
  deletion_window_in_days = 7
}

resource "aws_kms_key_policy" "kms_key_policy" {
  key_id = aws_kms_key.kms_key.id
  policy = jsonencode({
    Statement = [
      {
        Sid = "EnableIAMUserPermissions"
        Action = [
          "kms:*"
        ]
        Effect = "Allow"
        Principal = {
          AWS = join("", ["arn:aws:iam::", data.aws_caller_identity.current.account_id, "root"])
        }
        Resource = "*"
      },
      {
        Sid = "PolicyForKeyAdmin"
        Action = [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:TagResource",
          "kms:UntagResource",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion"
        ]
        Effect = "Allow"
        Principal = {
          AWS = data.aws_caller_identity.current.arn
        }
        Resource = "*"
      },
      {
        Sid = "PolicyForKeyUser"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Effect = "Allow"
        Principal = {
          AWS = join("", ["arn:aws:iam::", data.aws_caller_identity.current.account_id, ":user/", local.sops_user])
        }
        Resource = "*"
      },
      {
        Sid = "AllowAttachmentOfPersistentResources"
        Action = [
          "kms:CreateGrant",
          "kms:ListGrants",
          "kms:RevokeGrant"
        ]
        Effect = "Allow"
        Condition = {
          Bool = {
            "kms:GrantIsForAWSResource" : "true"
          }
        }
        Principal = {
          AWS = join("", ["arn:aws:iam::", data.aws_caller_identity.current.account_id, ":user/", local.sops_user])
        }
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_alias" "kms_key_alias" {
  name          = "alias/sopsing-key"
  target_key_id = aws_kms_key.kms_key.key_id
}