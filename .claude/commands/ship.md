---
description: Analyze → register issues → parallel PRs → merge. Run with a scope (e.g. /ship docs) or bare to sweep the whole repo.
argument-hint: "[scope, e.g. 'docs', 'Sources/CrossPromoKit/Services', or blank for everything]"
allowed-tools: ["*"]
---

Run the full pipeline for this repo: **analyze → register issues → implement in parallel → merge**.

Scope: $ARGUMENTS (empty means the whole repo).

## 1. Analyze

Read the actual code and docs in scope — do not work from memory or from what an earlier summary said. Look for correctness bugs, dead code, docs that contradict the code, missing tests, and inconsistencies between the two READMEs.

Every finding needs evidence: file, line, and the specific thing that is wrong. Verify it yourself before writing it down. A finding you could not reproduce is not a finding.

Report the findings to the user with a priority order and your reasoning. Then ask before registering — the user decides scope.

## 2. Register issues

One issue per concern, in Korean, each with: 문제 (evidence, file:line, quoted code), 해결 방안 (options if the call is genuinely open), 작업 checklist, 관련 파일.

State open decisions as open. If a fix requires a judgement the maintainer should make — a public API break, a policy choice — say so in the issue instead of silently picking.

**Group by file ownership, not by topic.** Two issues that touch the same file cannot run in parallel. When that happens, either merge them into one issue or plan to run them sequentially as stacked PRs.

## 3. Implement in parallel

Spawn one `issue-worker` agent per issue, all in one message, each with `isolation: "worktree"`. Give each: issue number, branch name, and **the explicit list of files it owns plus which files other agents own**.

For issues sharing a file, one agent handles both sequentially: PR A off main, PR B off A's branch (`gh pr create --base <A-branch>`).

Pass through the session URL for commit trailers and PR bodies.

## 4. Merge

When an agent reports back:

1. `gh pr checks <n>` — confirm green. Never merge on the agent's word alone.
2. `gh pr view <n> --json files` — confirm the diff contains only the files that agent owned.
3. `gh pr merge <n> --merge`.

**Do not pass `--delete-branch` while any stacked PR still targets that branch.** Deleting a base branch closes the stacked PR permanently — it cannot be reopened. Recovery is: rebase the orphaned branch onto main, re-verify, recover the old body with `gh pr view --json body`, and open a fresh PR.

Then clean up: `git worktree remove` the agent's worktree and delete the merged local branch.

Merge as each PR goes green rather than batching — later branches then rebase onto a main that already has the earlier work.

If a merge leaves another open PR conflicting, rebase it onto main yourself, re-run the verification commands, and `git push --force-with-lease`.

## 5. Report

Per issue: what changed, what was decided and why, what needs human verification. Surface anything the agents found outside their lanes as candidate follow-up issues, and ask whether to register them.

## Throughout

Report honestly. If CI failed, say so. If an agent's claim did not survive your check, say that too. The point of this pipeline is landed, verified work — not a green-looking summary.
