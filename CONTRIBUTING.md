# Contributing to openstate

Thanks for your interest in contributing to openstate.

## Maintainer-only pull requests

**Pull requests are restricted to approved maintainers.** Unsolicited PRs are declined. To contribute code, first apply for maintainer status by emailing michaelallenkuykendall@gmail.com.

**Anyone can contribute by:**
- Opening issues for bugs or feature requests
- Reporting what worked and what did not in your own sessions

## What is in this repository

The public parts of openstate: documentation, the skill, the installer and the website. The engine is proprietary and its source is not public; releases ship it prebuilt.

## For approved maintainers

1. Create a branch (`git checkout -b feature/foo`)
2. Make focused changes with clear commits
3. **Sign off your commits** (required): `git commit -s -m "Your message"` (see [DCO.md](DCO.md))
4. Run `bash -n install.sh` and, if you changed it, install into a scratch repository and run `./install.sh --check`
5. Open a pull request against `main`; the lead maintainer reviews and merges

```bash
git config format.signoff true  # sign off every commit automatically
```

## Scope

Changes should keep openstate per-repository, local-only and without configuration to babysit. We generally decline UI dashboards, complex configuration systems, and breaking changes to the tools agents already use.

## Maintainers

- **Lead Maintainer**: Michael A. Kuykendall (@Michael-A-Kuykendall)
- **Additional Maintainers**: none at present

To apply, email michaelallenkuykendall@gmail.com with your GitHub username, relevant experience, and the time you can give. Applications are reviewed when additional maintainers are needed.

## Questions?

Open a GitHub issue.
