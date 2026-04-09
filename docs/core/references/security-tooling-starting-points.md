---
title: Security Tooling Starting Points
description: A short, source-backed list of common scanner categories and official docs to begin from.
---

## Security Tooling Starting Points

These are starting points, not guarantees.

No single scanner covers the whole problem. Use layered checks, verify fit for
your environment, and prefer tools with clear official docs, active maintenance,
and a reviewable output format.

If you have a better recommendation, open an issue and make the case.

## Code And Rule Scanning

- [Semgrep](https://semgrep.dev/docs/getting-started/quickstart-ce): broad
  static analysis with rule packs and CI-friendly workflows
- [CodeQL](https://docs.github.com/en/code-security/concepts/code-scanning/codeql/about-code-scanning-with-codeql):
  GitHub's semantic code-scanning surface for codeql-based analysis

Use this category for application logic, unsafe patterns, and rule-based review
that goes beyond formatting or linting.

## Vulnerability And Dependency Scanning

- [Trivy](https://trivy.dev/docs/latest/guide/): vulnerability,
  misconfiguration, secret, and license scanning across images, filesystems,
  repositories, and more
- [OSV-Scanner](https://google.github.io/osv-scanner/): dependency
  vulnerability scanning against the OSV database

Use this category for dependency exposure, container or filesystem scanning,
and supply-chain awareness.

## Secret Scanning

- [Gitleaks](https://github.com/gitleaks/gitleaks): secret detection for git
  repos, directories, and CI workflows
- [TruffleHog](https://github.com/trufflesecurity/trufflehog): secret scanning
  with broad source support and verified-result workflows

Use this category for catching leaked credentials, tokens, keys, and other
sensitive material in code, history, and adjacent sources.

## Practical Rule

Do not stop at one category.

A reasonable starter stack is usually:

1. one code or rule scanner
2. one dependency or vulnerability scanner
3. one secret scanner

Then add repo-specific review gates and human judgment on top.
