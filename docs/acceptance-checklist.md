# Acceptance checklist

## Infrastructure

- [ ] Terraform plan targets only the approved test AWS account and Tokyo.
- [ ] ALB serves a valid TLS certificate; port 80 is closed rather than exposed.
- [ ] WAF managed rules and rate limiting are associated with the ALB.
- [ ] EC2 has no public IP, no inbound port 22, and is reachable through SSM.
- [ ] Instance metadata requires IMDSv2.
- [ ] EBS and every S3 bucket are encrypted.
- [ ] All S3 Block Public Access settings are enabled and ACLs are disabled.
- [ ] Upload/download succeeds only through the instance role or authorized
      presigned URLs; anonymous access fails.
- [ ] CloudTrail, ALB access logs, CloudWatch application logs, alarms, SNS, and
      the monthly budget are active.

## Release and recovery

- [ ] A correct backend archive deploys and becomes `current`.
- [ ] A checksum mismatch is rejected before extraction.
- [ ] A deliberately unhealthy release automatically rolls back.
- [ ] Manual rollback switches to `previous` and restores health.
- [ ] Rebooting/replacing an instance preserves S3 data and allows a clean
      redeployment from immutable artifacts.

## Product flow

- [ ] Authentication and refresh behavior work through the same-origin proxy.
- [ ] Authorized attachment upload, preview, download, and deletion work.
- [ ] Cross-tenant and unauthorized object access are denied.
- [ ] AI-disabled mode leaves non-AI workflows usable.
- [ ] Approved AI mode enforces user/tenant quotas, timeout, retry bounds, model
      allowlist, content controls, and an emergency kill switch.
- [ ] No student PII or prompt/response bodies appear in default logs.

## Performance

- [ ] Synthetic tests cover 10, 30, and 60 concurrent users.
- [ ] Record p50/p95 latency, 4xx/5xx rates, CPU, memory, disk, network, S3
      operations, provider latency, and token/cost totals.
- [ ] Test from real mainland China Mobile, China Unicom, and China Telecom
      networks before making a mainland performance claim.
- [ ] Complete 300 synthetic person-sessions without an unexplained error or
      budget-alarm breach.
