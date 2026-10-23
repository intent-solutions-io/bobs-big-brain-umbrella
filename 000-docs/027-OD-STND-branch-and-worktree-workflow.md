# Branch and worktree workflow

Transcribed 2026-10-23 from the local owner instructions cited below for the
managed repositories in [the topology manifest](../repos.yml). This reference
records the existing workflow and current authority boundaries. Source inspection
is separate from the pending governed-memory admission and retrieval acceptance.

## Choose the existing work first

One logical task has one branch and one PR. Sequential work stays in the existing
checkout. Before starting another branch, fetch the remote and inspect the
existing worktrees, branch tracking and open PRs. Continue related work where it
already lives. Record the owning Bead before implementation.

An additional worktree needs a real concurrency requirement: two logical tasks
must run at the same time, and the owning Bead must record that need before
creation. Do not create a worktree for each subagent or a branch just to run tests.
Parallel agents can share a checkout when their bounded edits and coordination
allow it. The older general advice to isolate shared-checkout work protects
against concurrent branch changes; it does not override the 2026-10-09 owner rule
or make every sequential task a new worktree.

Preserve unrelated dirty, untracked, stashed and unpublished work. Inspect before
switching branches or integrating remote changes; do not pull/rebase over a dirty
checkout. If work cannot be safely integrated within the authorized scope, record
what remains rather than discarding or silently stashing someone else's changes.

## Work and review

Follow the applicable repository's instructions. In this stack, branch from the
fetched remote default branch, verifying the applicable base against standard013
section 1 step 1. Make a focused change, run the owning repository's gates,
and push a reviewable PR. Umbrella documentation checks do not replace engine or
plugin tests. Hooks must not create, merge or delete branches. No automatic
merge, deletion or force-push is authorized by this workflow.

The [commit and PR standard, section 1 steps 4–6 and section 8](013-OD-STND-commit-branch-pr-conventions.md#1-the-workflow-never-merge-blind) requires
waiting for required checks and pending configured AI review, addressing supported
findings and passing the Outsider Test before a normal squash merge. Reviewer
output is advisory; a suggested owner decision does not create a new approval
requirement when source evidence or the existing authorization resolves it.
Use the existing `safe-merge OWNER/REPO PR --squash` command for the merge;
verify the interface in the installed command contract, invoke its `--dry-run`
first and follow that contract.
The command is explicitly operator-invoked; do not enable unattended merging or
bypass it with a direct merge command. Record an unavailable or timed-out review explicitly; do not
call it an approval.
Source merge, runtime bundle, release publication and deployed behavior are
separate states.

Apply current user and repository authorization to each operation. The locally
inspected team-maintainer profile lists ordinary in-scope status, branch creation,
staging, commits, pull/rebase, pushes, PRs and Beads Dolt push. This transcription
is not an independent permission grant. Where that profile applies, follow its
normal completion authority and repository review rules.
The profile lists routine pull/rebase among normal completion operations; this
does not authorize rewriting published history. Force-push, destructive history
rewrites, hard reset, deleting branches/tags and bypassing protection still need
explicit approval. A general cleanup-eligibility checklist
does not grant that approval.

## Recovery and cleanup boundaries

Keep the branch, worktree path or main-checkout designation, PR and current head
commit in the owning Bead. After a merge, verify the remote result and align a
clean checkout with remote main. This alignment is not a deployment.

Before retiring an owned worktree, verify the PR is merged, its porcelain status
is empty, no unpublished commits or omitted squash content remain, and no stashes
or unrelated work will be lost. Only then may an authorized clean-worktree removal
use `git worktree remove` without force. Dirty or untracked work is preserved and
reported. Branch/tag deletion remains subject to explicit approval; do not infer
it from the worktree checks. Bulk cleanup is a separate owner-approved task.

## Authority and scope

Local source records inspected on 2026-10-23 (operator transcription, not a
claim that private instruction files are publicly versioned):

- `~/.claude/CLAUDE.md`, “Git branches and worktrees (all repos)”, owner rule
  dated 2026-10-09, lines 399–408: one logical task/branch/PR, sequential checkout
  reuse, recorded concurrency exception, preservation and recovery.
- The same file, “Git authority in `~/000-projects`”, lines 393–397: explicitly includes ordinary
  pull/rebase and `bd dolt push`; retains approval for destructive or policy-
  bypassing actions. This is existing owner authorization, not a new grant here.
- `~/CLAUDE.md`, “Cross-session coordination”, item 4, line 18: older general
  shared-checkout isolation advice, reconciled with the dated owner rule above.
- `~/.claude/CLAUDE.md`, line 286, and the installed `~/bin/safe-merge`
  contract: use the merge guard. Its implementation is host-managed; this
  reference does not certify the wrapper implementation.

The older home-directory guidance is reconciled above. The current
managed-repository Git-authority profile explicitly retains approval for destructive
or policy-bypassing operations; that boundary takes precedence over an older
cleanup recipe containing a forced branch-deletion command. Historical instructions
are not rewritten by this reference.

Current repository instructions and user authorization remain controlling. This
reference does not expose private settings or create another task database: Beads
holds ownership, concurrency justification and recovery state. The related proof
and delivery boundaries are documented in
[the delivery snapshot](026-AT-RPRT-stabilization-delivery-state-2026-10-23.md).
