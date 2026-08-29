---
layout: post
title: "Hello, static web"
date: 2026-08-29 09:00:00 +0000
categories: meta
---

First entry. I've rebuilt this site as a plain-text log — inspired by
[megi's PinePhone log](https://xnux.eu/log/) — and moved hosting off GitHub Pages
onto AWS.

The setup is intentionally boring in the best way:

- **Jekyll** turns Markdown into static HTML.
- **S3** stores the files in a private bucket.
- **CloudFront** serves them over HTTPS from the edge, reading from S3 via Origin
  Access Control (the bucket is never public).
- **Route 53** points the domain at CloudFront.
- **GitHub Actions** builds and deploys on every push, authenticating to AWS with
  OIDC — no long-lived access keys stored anywhere.

Part of the point is to preach what I practise: if a personal blog doesn't need a
server, a database, or a PHP runtime, a surprising amount of "real" hosting
doesn't either. More on that — and on some product reviews — soon.
