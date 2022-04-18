# GitHub-Actions
Repo for public GitHub actions

[![GitHub CR Build and Push](https://github.com/tpayne/github-actions/actions/workflows/docker-image.yml/badge.svg)](https://github.com/tpayne/github-actions/actions/workflows/docker-image.yml)

GitHub Actions
--------------
The following are custom GitHub actions...

>| Action | Description |
>| -------- | ----------- |
>| `productmanifest` | This GitHub action is intended to be used with Helm based GitOps repos to update manifest files with rebuilt Docker image repo digests. This will trigger builds in monitored GitOps repos |

Notes
-----
- https://docs.github.com/en/actions/creating-actions/creating-a-docker-container-action
- https://docs.github.com/en/rest/reference/packages
- https://docs.github.com/en/github-ae@latest/rest/reference/actions#workflow-runs
