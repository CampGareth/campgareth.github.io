# ---------------------------------------------------------------------------
# GitHub Actions -> AWS via OIDC. No access keys are stored anywhere. GitHub
# issues a short-lived OIDC token for each workflow run; AWS trusts that token
# (scoped to this repo + branch) and hands back temporary credentials. This is
# the recommended pattern over long-lived IAM user access keys.
# ---------------------------------------------------------------------------

# Fetch GitHub's OIDC thumbprint dynamically rather than hard-coding it.
# Largely vestigial: since 2023 AWS skips thumbprint verification for IdPs whose
# certificate chains to its own trust store, which GitHub's does. The API still
# requires the field, so we compute it rather than pasting in a magic string.
data "tls_certificate" "github" {
  count = var.create_github_oidc_provider ? 1 : 0
  url   = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github" {
  count           = var.create_github_oidc_provider ? 1 : 0
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github[0].certificates[0].sha1_fingerprint]
  tags            = local.tags
}

# If the provider already exists in the account, look it up instead.
data "aws_iam_openid_connect_provider" "existing" {
  count = var.create_github_oidc_provider ? 0 : 1
  url   = "https://token.actions.githubusercontent.com"
}

locals {
  github_oidc_arn = var.create_github_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : data.aws_iam_openid_connect_provider.existing[0].arn
}

# Trust policy: only the OIDC provider, only our repo, only the deploy branch.
# The repo is pinned twice: by name (the sub claim, which AWS requires you to
# evaluate) and by its immutable numeric ID. Names are recyclable — rename or
# delete the account and someone else can register the same owner/repo, push a
# workflow on main, and present a token whose sub matches this policy exactly.
# The ID can't be recycled, so it closes that hole.
data "aws_iam_policy_document" "deploy_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.github_oidc_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # StringEquals, not StringLike: there is no wildcard here, and StringLike
    # would silently widen the policy if one ever crept into the variables.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:ref:refs/heads/${var.github_branch}"]
    }

    # AWS STS exposed GitHub's provider-specific claims as first-class condition
    # keys in January 2026; before that, sub was the only lever available.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:repository_id"
      values   = [var.github_repository_id]
    }
  }
}

resource "aws_iam_role" "deploy" {
  name               = "${var.site_name}-github-deploy"
  assume_role_policy = data.aws_iam_policy_document.deploy_assume.json
  tags               = local.tags
}

# Least privilege: sync the content bucket + invalidate this one distribution.
data "aws_iam_policy_document" "deploy_permissions" {
  statement {
    sid     = "SyncBucket"
    effect  = "Allow"
    actions = ["s3:PutObject", "s3:DeleteObject", "s3:ListBucket", "s3:GetObject"]
    resources = [
      aws_s3_bucket.content.arn,
      "${aws_s3_bucket.content.arn}/*",
    ]
  }

  statement {
    sid       = "InvalidateCdn"
    effect    = "Allow"
    actions   = ["cloudfront:CreateInvalidation"]
    resources = [aws_cloudfront_distribution.site.arn]
  }
}

resource "aws_iam_role_policy" "deploy" {
  name   = "deploy"
  role   = aws_iam_role.deploy.id
  policy = data.aws_iam_policy_document.deploy_permissions.json
}
