# aglabo - AI-Powered Development Lab

## OSS Development with AI power assisted

<!-- textlint-disable ja-technical-writing/sentence-length -->

**aglabo** is an organization dedicated to building high-quality OSS through AI-assisted development workflows.
We believe in **Configuration as Truth**.
This means enforcing quality through automation rather than documentation.

<!-- textlint-enable -->

## Core Philosophy

### Automation Over Documentation

<!-- textlint-disable ja-technical-writing/sentence-length -->

- **Configuration as Truth** - All rules live in config files, eliminating extensive documentation needs
- **Automate Everything** - Formatters, linters, and Git hooks prevent issues before they occur
- **AI-Powered Workflow** - Commit messages, documentation, and code reviews are AI-assisted
- **Zero Manual Checks** - Two-layer defense with local hooks and CI/CD pipelines

<!-- textlint-enable -->

### Development Principles

1. **Quality Through Automation** - Tools enforce standards consistently
2. **Developer Experience First** - Reduce cognitive load through intelligent defaults
3. **Security by Design** - Secret detection and vulnerability scanning built-in
4. **Continuous Improvement** - AI-driven insights for code quality and performance

## Key Projects

### .github - Shared Development Infrastructure

Our flagship repository providing common development infrastructure for all OSS projects:

<!-- textlint-disable ja-technical-writing/max-comma -->

- **Issue/PR Templates** - Standardized workflows for bug reports, feature requests, and pull requests
- **Automated Formatting** - dprint integration for Markdown, JSON, YAML, and TOML
- **Comprehensive Linting** - markdownlint, textlint, and cspell for document quality
- **Security Scanning** - gitleaks and secretlint to prevent secret leaks
- **Git Hooks Management** - lefthook for pre-commit automation
- **Commit Enforcement** - commitlint ensuring Conventional Commits format
- **CI/CD Workflows** - GitHub Actions for continuous quality assurance

<!-- textlint-enable -->

**Repository**: [aglabo/.github](https://github.com/aglabo/.github)

## Technology Stack

Our infrastructure is built on industry-standard tools:

| Category       | Tools                                  |
| -------------- | -------------------------------------- |
| **Formatting** | dprint, EditorConfig                   |
| **Linting**    | markdownlint-cli2, textlint, cspell    |
| **Security**   | gitleaks, secretlint, CodeQL           |
| **Git Hooks**  | lefthook                               |
| **Commit**     | commitlint, prepare-commit-msg         |
| **CI/CD**      | GitHub Actions                         |
| **AI Tools**   | Claude Code, Anthropic API, Claude SDK |

## Development Workflow

### For Contributors

1. **Setup**

   ```bash
   # Clone with submodules
   git clone --recursive <project-url>

   # Install Git Hooks
   lefthook install

   # Verify configuration
   dprint fmt
   ```

2. **Daily Development**

   ```bash
   # Write code → Auto-format on save
   # Commit → Automated checks run
   git commit

   # Push → CI/CD validates
   git push
   ```

3. **Commit Message Format**

   We follow [Conventional Commits](https://www.conventionalcommits.org/):

   <!-- textlint-disable ja-technical-writing/max-comma -->

   **Standard Types**: `feat`, `fix`, `docs`, `chore`, `test`, `refactor`, `perf`, `ci`

   **Custom Types**: `config`, `release`, `merge`, `build`, `style`, `deps`

   <!-- textlint-enable -->

### Prohibited Actions

- Never bypass hooks with `--no-verify`
- Never commit secrets (blocked by gitleaks)
- Never manually format code (handled by dprint)
- Always follow Conventional Commits format

## Community

### Contributing

We welcome contributions. Each repository includes:

- Issue Templates for bug reports, feature requests, and general topics
- PR Template with checklist for code reviews
- Code of Conduct with community guidelines for respectful collaboration
- Security Policy with procedures for reporting vulnerabilities

### Getting Help

- Issues: Report bugs or request features in the respective repository
- Discussions: Ask questions and share ideas in GitHub Discussions
- Security: Report vulnerabilities privately via Security Policy

## AI-Assisted Development

Our projects leverage AI throughout the development lifecycle:

- Code Generation: AI-powered code completion and refactoring
- Documentation: Automated README generation and inline comments
- Commit Messages: AI-generated messages following Conventional Commits
- Code Review: AI-assisted pull request reviews and suggestions
- Testing: Intelligent test case generation and coverage analysis

<!-- textlint-disable ja-technical-writing/sentence-length -->

All AI-generated content is reviewed and approved by human maintainers.
This ensures quality and accuracy.

<!-- textlint-enable -->

## License

All aglabo projects are released under the **MIT License** unless otherwise specified.

Copyright (c) 2025- aglabo

## Acknowledgments

This organization and its projects are maintained with the support of AI agent assistants:

- Kobeni: Infrastructure and automation specialist
- Tsumugi: Documentation and content creation
- Elpha: Code quality and testing advocate

---

Built with AI. Maintained with Care. Open for All.
