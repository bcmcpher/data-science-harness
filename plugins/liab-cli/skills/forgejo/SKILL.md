---
name: forgejo
description: >
  Auto-invoke when the user wants to create or inspect a repository on a self-hosted Forgejo (or
  Gitea) instance so a DataLad dataset can be served from lab-controlled infrastructure. Trigger on
  "create the repo on our Forgejo", "make a repository on the lab git host", "is our Forgejo
  reachable", "what's the clone URL for the self-hosted repo", or /forgejo. Do NOT trigger for
  standing the instance itself up (that is a pyinfra deployment), for registering the result as a
  DataLad sibling (that is a datalad operation), or for pushing data to a sibling that already
  exists.
argument-hint: '[check|probe|create-repo] [--url <instance>] [--owner <user-or-org>] [--repo <name>]'
user-invocable: true
disable-model-invocation: false
allowed-tools: Read, Bash, Grep, Glob
---

# Skill: forgejo

Create and inspect repositories on a self-hosted Forgejo instance, and report the URLs a DataLad
sibling would be registered against.

**Read this before anything else: this skill does not stand up an instance.** Installing Forgejo,
its database, its reverse proxy and its systemd units is declarative infrastructure, and it belongs
in the pyinfra deployment where it can be planned, diffed and re-applied. A Forgejo installed by a
sequence of ad hoc commands from here is a host nobody can reproduce. If the instance does not
exist, say so and hand back to `plugins/liab-cli/skills/pyinfra/SKILL.md`.

What this skill does own is the part that happens *after* the instance exists and is not
infrastructure: the repository, its visibility, and the URL that goes into a sibling.

## Steps

1. **Check the tool and the credential before anything else.**
   ```bash
   bash plugins/liab-cli/scripts/check-tools.sh forgejo
   ```
   Exit 0 means a client and a token are present. Exit 1 means they are not; report the `enable:`
   hint and stop. **This is a presence check only** — it contacts nothing, so a token that has been
   revoked or scoped too narrowly passes here and fails at the instance. That failure is reported as
   `failed`, never as `unavailable`.

2. **State the instance, the owner and the repository name back before acting.** All three come from
   the user or the deployment's config. A self-hosted instance has no canonical hostname the way
   `zenodo.org` does, and creating a repository on the wrong one is not a local mistake.
   ```
   instance: https://git.lab.example.org
   owner:    <user or organisation>
   repo:     <name>
   ```
   If any of the three was not supplied, ask. Do not derive the repository name from the dataset
   directory, and do not assume the token's own user is the intended owner.

3. **Probe the instance before creating anything.**
   ```bash
   curl -sS -f "$FORGEJO_URL/api/v1/version"
   ```
   Report the version the instance returns. A connection failure here is the honest answer to "is
   the lab git host up" — report it as `failed` with the URL, and do not fall back to a public host.

4. **Check whether the repository already exists.**
   ```bash
   curl -sS -o /dev/null -w '%{http_code}\n' \
     -H "Authorization: token $FORGEJO_TOKEN" \
     "$FORGEJO_URL/api/v1/repos/<owner>/<repo>"
   ```
   `200` means it exists — report it and its clone URLs, and **stop**. Creating over an existing
   repository is not this skill's decision to make, and an existing repository may already be
   serving a dataset.

5. **Create the repository only on an explicit instruction, with visibility stated.**
   ```bash
   curl -sS -f -X POST \
     -H "Authorization: token $FORGEJO_TOKEN" \
     -H 'Content-Type: application/json' \
     -d '{"name": "<repo>", "private": <true|false>, "auto_init": false}' \
     "$FORGEJO_URL/api/v1/user/repos"          # or /api/v1/orgs/<org>/repos for an organisation
   ```
   **`private` has no default here.** Ask which it is. A dataset repository created public when it
   should have been private is a disclosure, and the reverse is a broken link in a paper; neither is
   recoverable by editing a flag afterwards. `auto_init: false` matters too — an initial commit
   created by the server gives the dataset a history it did not have.

6. **Report the URLs, and hand the sibling registration back.**
   ```bash
   ssh_url=$(curl -sS -H "Authorization: token $FORGEJO_TOKEN" \
     "$FORGEJO_URL/api/v1/repos/<owner>/<repo>" | python3 -c 'import json,sys; print(json.load(sys.stdin)["ssh_url"])')
   ```
   Registering that URL as a DataLad sibling, and serving annexed content from it, are the datalad
   doer's. Report the URLs and say which step comes next rather than running it.

7. **Report.**
   ```
   op:        forgejo-<check|probe|create-repo>
   instance:  <URL, and the version it reported>
   owner:     <owner>
   repo:      <name>
   result:    exists | created | failed | unavailable
   visibility: private | public   (as stated by the user, echoed back)
   clone:     <ssh_url> / <clone_url>
   notes:     <what this did not verify — that annexed content can be retrieved from it>
   ```

## Constraints

- **Never install, configure or upgrade a Forgejo instance from here.** Instance setup is a pyinfra
  deployment. A host configured by ad hoc commands cannot be planned, diffed or rebuilt, which is
  the whole reason the deployment is declarative.
- **Never create a repository without being told its visibility.** There is no safe default:
  `private` hides a dataset a paper links to, `public` discloses one that may carry participant
  data. Both are the researcher's call and neither is undoable by a later flag.
- **Never create a repository on an instance the user did not name.** A self-hosted host has no
  canonical name, so there is nothing to fall back to — and there is no public default to try.
- **Never overwrite, re-initialise or delete an existing repository.** If it exists, report it and
  stop. It may already be serving a dataset.
- **Never print a token, and never write one into a config file, a remote URL or a report.** Report
  that a credential is present or absent, never its value.
- **Never register the sibling or push data.** That is the datalad doer's, and the difference
  matters: this skill has created a place to put data, which is not the same as having put it there.
- **Never report a created repository as a working remote.** The standard this capability answers to
  is a `datalad get` that retrieves annexed content from the host. Until that runs, say `created`.
- **Never mirror the dataset to a public forge "as a backup".** Data sovereignty is the reason this
  capability exists; a convenience copy on a third-party host defeats it silently.
- Do not commit. The datalad doer owns `datalad save`.
