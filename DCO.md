# Developer Certificate of Origin (DCO)

## Overview

openstate uses the Developer Certificate of Origin (DCO) to ensure that all contributions are properly licensed and that contributors have the right to submit their code.

## What is DCO?

The DCO is a lightweight way for contributors to certify that they wrote or otherwise have the right to submit their contribution. It's an industry-standard alternative to Contributor License Agreements (CLAs) used by projects like Linux kernel, Docker, and GitLab.

## DCO Text

By making a contribution to this project, I certify that:

```
Developer Certificate of Origin
Version 1.1

Copyright (C) 2004, 2006 The Linux Foundation and its contributors.

Everyone is permitted to copy and distribute verbatim copies of this
license document, but changing it is not allowed.

Developer's Certificate of Origin 1.1

By making a contribution to this project, I certify that:

(a) The contribution was created in whole or in part by me and I
    have the right to submit it under the open source license
    indicated in the file; or

(b) The contribution is based upon previous work that, to the best
    of my knowledge, is covered under an appropriate open source
    license and I have the legal right to submit that contribution
    under the same license terms (unless I am permitted to submit
    under a different license), as indicated in the file; or

(c) The contribution was provided directly to me by some other
    person who certified (a), (b) or (c) and I have not modified
    it.

(d) I understand and agree that this project and the contribution
    are public and that a record of the contribution (including all
    personal information I submit with it, including my sign-off) is
    maintained indefinitely and may be redistributed consistent with
    this project or the open source license(s) involved.
```

## How to Sign Off

Add a `Signed-off-by` line to your commit message:

```bash
git commit -s -m "Your commit message"
```

This will append a line like:
```
Signed-off-by: Your Name <your@email.com>
```

**Quick setup for auto sign-off:**
```bash
git config format.signoff true
```

All commits must include a valid `Signed-off-by` line. Commits without it will be rejected.