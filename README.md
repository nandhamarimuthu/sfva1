# SkyForge Vulnerable AWS Fixture

A **synthetic, intentionally misconfigured repository** for testing infrastructure-security, AWS-cost-optimization, code-quality, and test-coverage scanners. It includes Terraform for EC2, Lambda, SQS, S3, IAM, and CloudWatch plus a small Python Lambda handler.

> [!CAUTION]
> This is a scanner fixture, not a deployable baseline. Terraform intentionally contains insecure and wasteful patterns. **Do not run `terraform apply` in a real/shared account.** Expensive compute is disabled by default, but other resources can still incur charges if enabled. Prefer static scanning (`checkov`, `tfsec`, `ruff`, `pytest --cov`) and use an isolated sandbox account for any deployment. Never put real credentials in this repository.

## Layout

```text
skyforge-vulnerable-aws-fixture/
├── terraform/
│   ├── versions.tf
│   ├── variables.tf
│   ├── main.tf
│   ├── iam.tf
│   └── outputs.tf
├── unit-tests/
│   └── test_handler.py
├── functional-tests/
│   └── test_handler_contract.py
├── main/
│   └── code/
│       └── handler.py
├── pyproject.toml
├── .gitignore
└── README.md
```

## Intentional findings for scanner validation

### Security / configuration
- EC2 security group permits SSH from `0.0.0.0/0`.
- S3 bucket public-access blocking and default encryption are absent.
- SQS queue server-side encryption is absent and message retention is set high.
- Lambda execution role includes wildcard actions/resources.
- Lambda environment variables include a fake placeholder secret (not a real credential).
- CloudWatch log retention is not configured.
- EC2 root volume encryption is not explicitly enabled.

### Cost / waste
- Large EC2 instance type (`m7i.4xlarge`) is available behind a variable that defaults to `false`.
- Lambda memory and timeout are oversized for the tiny handler.
- S3 lifecycle/expiration policies are absent.
- SQS retention is configured for 14 days.
- No required cost-allocation tags are enforced.

### Code / testing quality
- Handler has sparse error handling and simple input assumptions.
- Unit and functional tests are deliberately minimal; coverage is expected to be low.
- Ruff and pytest-cov are configured so your scanner can report lint/test findings.

## Run static checks (no AWS deployment)

```bash
python -m venv .venv
source .venv/bin/activate
pip install -e '.[dev]'
pytest --cov=main/code --cov-report=term-missing
ruff check .
```

Terraform static scan examples:

```bash
checkov -d terraform
# or
 tfsec terraform
```

## Terraform safety

`enable_expensive_ec2` defaults to `false`; this only gates the large EC2 instance. Other resources are still real billable resources if you apply. For scanner testing, **do not apply**. If you intentionally deploy in a disposable sandbox, review `terraform plan` first and destroy immediately after testing.
