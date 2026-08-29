# Infrastructure — static hosting for campgareth.co.uk

This directory stands up the AWS hosting for the blog as **static files behind a
CDN** — no servers, no databases, no PHP runtime. It's deliberately minimal and
commented so it can double as a reference.

## Why this shape?

```
        GitHub push (main)
              │
              ▼
   GitHub Actions  ──OIDC──►  assume IAM role (no stored keys)
   builds _site/                    │
              │ aws s3 sync          ▼
              ▼                 private S3 bucket  ◄──OAC──  CloudFront ──TLS──►  visitor
        (content bucket)                                        ▲
                                                          Route 53 alias
                                                     (apex + www → CloudFront)
```

- **S3 + CloudFront instead of a server.** Static files scale trivially, cost
  almost nothing, and have no runtime to patch or exploit.
- **Private bucket + Origin Access Control (OAC).** The bucket is never public;
  only this CloudFront distribution can read it (enforced by the bucket policy).
  This is the current AWS best practice — no public buckets, no website endpoint.
- **OIDC instead of access keys.** GitHub Actions assumes a role with a
  short-lived token scoped to `repo + branch`. Nothing long-lived is stored.
- **Apex is canonical.** The site serves at `campgareth.co.uk`; `www` 301-redirects
  to it via a CloudFront Function. Apex hosting uses a Route 53 *alias* record, so
  it coexists cleanly with your other subdomains in the same zone.

## Files

| File | What it does |
|------|--------------|
| `bootstrap/` | One-time: creates the S3 bucket that stores Terraform state. |
| `providers.tf` | Providers, S3 remote-state backend, shared locals. |
| `s3.tf` | Private content bucket (encrypted, versioned, no public access). |
| `acm.tf` | TLS cert in us-east-1, DNS-validated. |
| `cloudfront.tf` | Distribution, OAC, security headers, viewer function, bucket policy. |
| `cloudfront_function.js.tftpl` | Edge function: www→apex redirect + directory-index rewrite. |
| `route53.tf` | Alias records for apex + www. |
| `iam.tf` | GitHub OIDC provider + least-privilege deploy role. |
| `outputs.tf` | Values to copy into GitHub repo variables. |

## Requirements

- Terraform **>= 1.10** (uses native S3 state locking, no DynamoDB).
- AWS credentials with admin-ish permissions for the initial apply (locally, e.g.
  `aws sso login` / `AWS_PROFILE`). The *deploy* uses the scoped OIDC role, not this.
- The Route 53 hosted zone for `campgareth.co.uk` already exists.

## Runbook

### 1. Create the state bucket (once)

```bash
cd bootstrap
terraform init
terraform apply
cd ..
```

If you change `state_bucket_name`, update the `backend "s3"` block in
`providers.tf` to match.

### 2. Apply the main stack

```bash
terraform init      # configures the S3 backend
terraform fmt -check
terraform validate
terraform plan      # review — creates S3, ACM, CloudFront, Route 53, IAM
terraform apply
```

ACM validation and the CloudFront rollout take a few minutes. When it finishes,
note the outputs:

```bash
terraform output
```

> If apply errors that the GitHub OIDC provider already exists, re-run with
> `-var create_github_oidc_provider=false`.

### 3. Wire up GitHub Actions

In the repo → **Settings → Secrets and variables → Actions → Variables**, add
(from `terraform output`):

| Variable | Value |
|----------|-------|
| `AWS_DEPLOY_ROLE_ARN` | `deploy_role_arn` |
| `AWS_REGION` | `aws_region` |
| `AWS_S3_BUCKET` | `content_bucket_name` |
| `AWS_CLOUDFRONT_DISTRIBUTION_ID` | `cloudfront_distribution_id` |

Push to `main` (or run the workflow manually) to do the first deploy.

### 4. Test before cutover

The Route 53 records already point at CloudFront, but you can sanity-check the
distribution directly first:

```bash
curl -I https://$(terraform output -raw cloudfront_domain_name)/
```

Expect `HTTP/2 200`, HSTS + `x-content-type-options` headers, and `/about/`
resolving (directory-index rewrite working).

### 5. Cut over & decommission GitHub Pages

- Confirm `https://campgareth.co.uk` and `https://www.campgareth.co.uk`
  (redirects to apex) both work.
- In the GitHub repo → **Settings → Pages**, set source to **None** so GitHub
  Pages stops publishing (the `CNAME` file has already been removed from the repo).

## Troubleshooting

### ACM validation fails with `CAA_ERROR`

ACM couldn't issue the cert because a **CAA** DNS record forbids Amazon from issuing
for that name. Most commonly this is a *stale record from the old host*: if
`www.campgareth.co.uk` is still a `CNAME` to `campgareth.github.io` (GitHub Pages),
CAA checking follows the CNAME to `github.io`, whose CAA set authorises only
DigiCert/Let's Encrypt/Sectigo — not Amazon.

Fix: delete the stale `www` CNAME (it has to go for the migration anyway), then
request a **new** cert — a DNS-validated cert that has entered `FAILED` never retries:

```bash
ZONE_ID=$(aws route53 list-hosted-zones-by-name --dns-name campgareth.co.uk \
  --query "HostedZones[?Name=='campgareth.co.uk.'].Id | [0]" --output text)
aws route53 change-resource-record-sets --hosted-zone-id "$ZONE_ID" \
  --change-batch '{"Changes":[{"Action":"DELETE","ResourceRecordSet":{"Name":"www.campgareth.co.uk.","Type":"CNAME","TTL":3600,"ResourceRecords":[{"Value":"campgareth.github.io"}]}}]}'

terraform apply -replace="aws_acm_certificate.site"
```

If the apex itself ever needs CAA (e.g. another CA is pinned on the zone), authorise
Amazon with: `campgareth.co.uk. CAA 0 issue "amazon.com"`.

## Teardown

```bash
terraform destroy          # main stack
# The state bucket has prevent_destroy; remove that guard first if you truly want it gone.
```
