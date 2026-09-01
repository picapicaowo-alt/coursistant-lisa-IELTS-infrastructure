# Architecture

## Request path

```text
Authenticated test user
        |
        | HTTPS 443
        v
Route 53 -> AWS WAF -> Application Load Balancer
                            |
                            | private target, port 8080
                            v
                   EC2 Auto Scaling Group
                   Nginx + immutable releases
                      |       |          |
                   /api   /ai-agent  /study-support
                      |       |          |
                    8083     8090       8091 (loopback only)
                      |
                      +---- private S3 through gateway endpoint
                      +---- Secrets Manager through instance role
                      +---- approved AI provider over outbound TLS
```

The network spans two Availability Zones. The test configuration uses one NAT
Gateway to control cost; `high_availability_nat = true` creates one per AZ. The
Application Load Balancer always spans both public subnets. Application
instances have no public IP and no inbound SSH rule.

## Availability boundary

The default Auto Scaling desired capacity is one because this is a limited
test. It is intentionally not described as highly available. Set desired and
minimum capacity to two, enable per-AZ NAT, and complete failure testing before
making a production availability claim.

## Storage boundary

- `uploads`: private application objects. Browser access requires a short-lived
  presigned URL issued after backend authorization.
- `artifacts`: immutable backend/frontend release archives.
- `audit`: ALB access logs, S3 access logs, and CloudTrail management events.

All buckets block public access, enforce bucket-owner ownership, reject
non-TLS requests, and enable versioning. Application buckets use the stack KMS
key; the audit bucket uses S3-managed encryption for ALB log-delivery
compatibility, while CloudTrail log files specify the stack KMS key. Lifecycle rules
remove abandoned multipart uploads and expire old noncurrent versions/logs.

## Deployment boundary

Infrastructure and application deployment are separate:

- Terraform provisions the server, routing, storage, IAM, monitoring, and the
  release manager.
- The frontend repository produces a static `dist` archive.
- The backend team produces a language-neutral archive containing `bin/start`
  and health behavior defined in `docs/backend-handoff.md`.
- Release scripts upload a versioned archive to S3 and execute the server-side
  release manager over AWS Systems Manager.
