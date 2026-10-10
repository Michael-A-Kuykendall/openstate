# Contributing to openstate

Thanks for your interest in contributing to openstate!

## 🚨 IMPORTANT: Maintainer-Only Pull Requests

**Pull requests are restricted to approved maintainers only.** Unsolicited PRs will be declined. To contribute code, you must first apply for maintainer status by emailing michaelallenkuykendall@gmail.com.

**Non-maintainers can contribute by:**
- Opening issues for bugs or feature requests
- Participating in GitHub Discussions
- Providing feedback and testing

## How to Contribute
1. Fork the repo and create a branch (`git checkout -b feature/foo`)
2. Make your changes with clear commits and tests if applicable
3. **Sign off your commits** (required): `git commit -s -m "Your message"`
4. Run existing tests to ensure nothing breaks (`cargo test`)
5. Ensure code quality (`cargo fmt && cargo clippy`)
6. Open a Pull Request against `main`

### Developer Certificate of Origin (DCO)
All contributions must be signed off with the Developer Certificate of Origin. This certifies that you have the right to contribute your code. See [DCO.md](DCO.md) for details.

**Quick setup:**
```bash
git config format.signoff true  # Auto sign-off all commits
```

## Code Style
- Rust 2021 edition
- Use `cargo fmt` and `cargo clippy` before submitting
- Keep PRs small and focused - large refactors may be rejected
- Add tests for new functionality
- Document public APIs with rustdoc comments

## Contribution Scope
Features should align with the **openstate philosophy**:
- **Per-repo install**: `install.sh` targets `.opencode/` (not global)
- **Semantic fact lifecycle**: facts enter on real events, exit on paired events
- **Crash recovery**: in-progress work persists across process death
- **Provenance**: `openstate_why` shows where any fact came from
- **Compact/prune**: dead records collected at session boundaries

## What We Welcome
- Bug fixes with test cases
- Performance improvements
- AI tool compatibility enhancements
- Documentation improvements
- Platform-specific fixes
- Test coverage improvements

## What We Generally Reject
- Features that bloat binary size significantly
- Complex configuration systems
- UI/dashboard components (invisible infrastructure philosophy)
- Breaking changes to established AI tool APIs
- Features not aligned with session-state engine scope

## Review Process

**IMPORTANT: Pull Request Access is Restricted**
- Only approved maintainers may submit pull requests
- All contributions from non-maintainers will be declined
- Code contributions require pre-approval via maintainer application process

**For Approved Maintainers:**
- All PRs require review and approval from the lead maintainer
- Merge authority is reserved to maintain project direction
- We aim to review PRs within 1-2 business days
- Constructive feedback will be provided for rejected PRs

## Development Setup
```bash
# Clone and setup
git clone https://github.com/Michael-A-Kuykendall/openstate
cd openstate
cargo build

# Run tests
cargo test

# Check formatting and linting
cargo fmt --check
cargo clippy -- -D warnings
```

## Maintainer Process

### Current Maintainer Structure
- **Lead Maintainer**: Michael A. Kuykendall (@Michael-A-Kuykendall)
- **Additional Maintainers**: Currently none (solo-maintained project)

### Becoming a Maintainer
Currently, openstate is maintained by a single maintainer to ensure consistent vision and rapid iteration. **Code contributions require pre-approved maintainer status.**

**To apply for maintainer status:**
1. **Private Application**: Email michaelallenkuykendall@gmail.com with:
   - Your GitHub username and relevant experience
   - Area of expertise (e.g., Rust performance, AI tooling, session state)
   - Time commitment you can provide
   - Why you'd like to help maintain openstate
2. **Evaluation Process**: Applications are reviewed when additional maintainers are needed
3. **No Unsolicited PRs**: Code contributions without prior approval will be declined

### Maintainer Responsibilities
When additional maintainers are added, they will:
- Review and approve pull requests
- Triage and respond to issues
- Maintain code quality standards
- Participate in release planning
- Uphold the openstate philosophy and project direction

*Note: The project may remain solo-maintained until contribution volume requires additional help.*

## Recognition
Contributors are acknowledged in `AUTHORS.md` after a merged PR.

## Questions?
Open a GitHub Discussion or ping @Michael-A-Kuykendall in your PR.