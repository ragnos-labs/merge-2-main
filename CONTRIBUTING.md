# Contributing to merge-2-main

Thank you for your interest in contributing. This is a documentation-only repository:
no executable code, just architectural patterns, guides, and templates for multi-agent
coordination.

## How to Contribute

### Reporting Issues

- Use [GitHub Issues](https://github.com/ragnos-labs/merge-2-main/issues) for bugs, unclear docs, or suggestions
- Include which document is affected and what is confusing or incorrect

### Submitting Changes

1. Fork the repository
2. Create a feature branch (`git checkout -b improve-worker-swarm-doc`)
3. Make your changes
4. Verify all relative links resolve
5. Submit a pull request

### What We Accept

- Clarity improvements to existing docs
- New worked examples showing patterns in real scenarios
- Corrections to inaccurate or outdated information
- Translations (open an issue first to coordinate)
- New templates that complement existing patterns
- New source-backed references to official runtime or protocol docs

### What We Do Not Accept

- Changes that add tooling-specific dependencies (the framework is tool-agnostic)
- Marketing or promotional content
- Docs that require proprietary software to follow
- Unattributed copy-paste from third-party docs or repos

## Style Guide

- ASCII only (no unicode em dashes, curly quotes, or special characters)
- Markdown with YAML frontmatter
- Concrete over abstract: show examples, not just rules
- Every pattern doc should cover both Claude Code and Codex usage where applicable

## Sourcing And Attribution

- Prefer primary sources for runtime-specific claims.
- Prefer linking and summarizing over copying upstream text.
- If you adapt an idea from another repo, protocol, or playbook, cite it in the
  PR and add the durable link near the claim when appropriate.
- If you copy substantial third-party material, preserve the original notice and
  license terms exactly as required.

Start with [docs/core/references/ecosystem-source-map.md](docs/core/references/ecosystem-source-map.md).

## License

By contributing, you agree that your contributions will be licensed under the Apache 2.0 License.
