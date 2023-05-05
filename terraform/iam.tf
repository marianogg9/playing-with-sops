resource "aws_iam_user" "sops_user" {
  name = local.sops_user
  path = "/"
}

data "aws_iam_policy_document" "sops_user_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:DescribeKey"
    ]
    resources = [
      aws_kms_key.kms_key.arn
    ]
  }
}

resource "aws_iam_user_policy" "sops_user_policy" {
  name   = "sops-user-policy"
  user   = aws_iam_user.sops_user.name
  policy = data.aws_iam_policy_document.sops_user_policy_document.json
}