---
name: publish-skills
runtime: claude-code
description: |
  Checklist for publishing an Agent Skills spec-compliant skill to GitHub.
  Use when: (1) preparing a skill for open source release, (2) reviewing a
  skill before first commit, (3) "is this skill ready to publish?", (4) auditing
  an existing published skill for spec compliance. Covers SKILL.md frontmatter
  fields (required + optional), directory structure, LICENSE.txt, README patterns,
  consistency review, and common pre-publish mistakes.
license: MIT
metadata:
  author: jeremyknows
  version: "1.0.0"
  autoresearch-baseline: "7/12 quality score (2026-03-18)"
---

# Publish an Agent Skill

Checklist for taking a working skill from "works locally" to "ready for GitHub."

## The Gap Between Valid and Publishable

The Agent Skills spec (agentskills.io) says only `name` and `description` are required in SKILL.md frontmatter. But most published skills also include `license` and a `LICENSE.txt` file. Some include `compatibility` and `metadata` when relevant. Following only the minimum requirements produces a skill that works but looks unfinished on GitHub.

## Pre-Publish Checklist

### 1. SKILL.md Frontmatter

**Required fields:**
```yaml
name: my-skill-name          # lowercase alphanumeric + hyphens, 1-64 chars
description: >                # 1-1024 chars (spec); some platforms enforce 200
  Describe what the skill does and when to use it...
```

**Should-have fields (common in published skills):**
```yaml
license: MIT                  # or "Complete terms in LICENSE.txt"
compatibility: Requires Node.js >= 22 and network access to X API
metadata:
  author: your-org
  version: "1.0.0"
```

**Optional fields (use when relevant):**
```yaml
allowed-tools: Bash(git:*) Read  # Experimental — pre-approved tools
```

### 2. Name Validation

- Lowercase alphanumeric + hyphens only
- No leading/trailing hyphens
- No consecutive hyphens (`--`)
- **Must match parent directory name** (e.g., `name: my-skill` in `my-skill/SKILL.md`)

### 3. Directory Structure

```
my-skill/
├── SKILL.md          # Required — skill instructions + frontmatter
├── LICENSE.txt        # Should-have — full license text
├── README.md          # Should-have — GitHub-facing documentation
├── .gitignore         # Should-have — .DS_Store, node_modules/
└── scripts/           # If applicable — executable helpers
    └── my-script.js
```

Optional directories per spec: `references/`, `assets/`

### 4. SKILL.md Body

- Under 5000 tokens recommended (roughly 500 lines as a heuristic)
- Move detailed reference material to `references/` directory
- Include: prerequisites, quick start, command reference, troubleshooting
- All code examples should use consistent full paths

### 5. LICENSE.txt

Every official Anthropic skill bundles a license file. Include one even if it's just MIT. Match the `license` frontmatter field.

### 6. README.md Patterns

Learned from studying well-received published skills:

| Section | Why |
|---------|-----|
| **What it does** (bullet list) | Scannable overview — people decide in 5 seconds |
| **Install** (for each platform) | Instructions for each supported agent (Claude Code, Cursor, etc.) with `git clone` |
| **Setup** (numbered steps) | Prerequisites with verification commands |
| **Usage: Natural language** | People forget they can just talk to Claude — show examples |
| **Usage: CLI commands** | Every command with comments |
| **Commands table** | Quick reference with usage syntax |
| **Configuration** | Env vars, config files, defaults |
| **Security** | Token handling, what's logged, recommendations |
| **Limitations** | Honest about what it can't do — builds trust |
| **Troubleshooting** | Symptom → Cause → Fix table |
| **File structure** | Tree view with one-line descriptions |

### 7. Consistency Review (Do This Last)

Run through these checks before the first commit:

- [ ] All clone/install URLs match the actual repo (org/name)
- [ ] All code examples use consistent paths (full path vs relative — pick one)
- [ ] LICENSE year matches current year
- [ ] LICENSE copyright holder matches repo owner
- [ ] No dead code (unused constants, unreachable branches)
- [ ] No hardcoded personal references (usernames, paths, server names)
- [ ] `.gitignore` includes `.DS_Store` and any generated directories
- [ ] Git user.name and user.email are set correctly for the commit
- [ ] Script has correct executable permissions (`chmod +x`)
- [ ] Smoke test passes after all edits (run the actual script)

### 8. Common Pre-Publish Mistakes

| Mistake | How to catch it |
|---------|----------------|
| Clone URLs point to wrong org/repo | Grep README for `github.com` |
| Code examples mix relative and full paths | Search for `node ` without `~/` prefix |
| LICENSE says wrong year or copyright holder | Read it — don't assume the template was right |
| Dead code from development (unused imports, constants) | Grep for each constant/variable, verify it's referenced |
| Committer identity shows machine user, not author | `git log --format="%an <%ae>"` |
| SKILL.md `name` doesn't match directory name | Compare frontmatter to `basename $(pwd)` |
| Description exceeds 1024 chars | `grep -A20 'description' SKILL.md \| wc -c` |
| Fleet-internal personas / paths leak into "public" SKILL.md | **Run the publish-time sanitizer pipeline (Section 9)** |

### 9. Publish-Time Sanitizer Pipeline (MANDATORY for fleet skills with private context)

**Why this exists.** A skill authored inside a working agent fleet (Atlas, etc.) accumulates fleet-specific signal — named agent references (Orchestrator, Researcher), workspace paths (`~/my-fleet/...`), war stories with private context. This signal makes the skill MORE effective for fleet agents but blocks public publish. The sanitizer pipeline lets you maintain ONE source of truth (the canonical fleet-rich SKILL.md) and emit a clean publishable copy on demand. Trust posture: defense in depth — automated transforms + post-scanner deny-list + manual diff before push.

**Pipeline (3 stages, each fail-loud):**

```bash
# Set SANITIZER_DIR to where publish-skills/scripts/ is installed on your machine
SANITIZER_DIR=<skills-install>/publish-skills/scripts  # adjust to your install path

# Stage 1: Transform known-pattern leaks (paths, conventions). Strips author-marked private blocks.
# Refuses if output path equals input path (would destroy canonical fleet copy).
bash $SANITIZER_DIR/publish-sanitize.sh path/to/SKILL.md /tmp/SKILL.publish.md

# Stage 2: Deny-list scan on output. STRICT BY DEFAULT: WARN matches are treated as BLOCK.
# Exit 2 = BLOCK (publish forbidden); 1 = WARN-only with --allow-warn; 0 = clean.
bash $SANITIZER_DIR/post-scan.sh /tmp/SKILL.publish.md
# If exit 2: remediate (wrap source in atlas-private markers OR rephrase) and re-run from Stage 1.
# If you intentionally want to ship despite WARN matches: rerun with `--allow-warn` and review carefully.

# Stage 3: Manual diff. Operator-in-loop final stop.
# For first publish (no prior published version exists):
diff -u path/to/SKILL.md /tmp/SKILL.publish.md | less
# Review every removal as intentional, every transform as desired.
# For subsequent publishes:
diff -u path/to/last-published-SKILL.md /tmp/SKILL.publish.md | less

# Then: cp /tmp/SKILL.publish.md path/to/public-repo/SKILL.md && gh pr create ...
```

**Author discipline (the only manual surface):**

Mark fleet-private content with markers; the sanitizer strips between them. Markers are case-insensitive and whitespace-tolerant inside (e.g. `atlas-private:start` with any case/spacing variation); nested markers are rejected (sanitizer exits 2):

```markdown
<!-- [your-fleet]-private:start -->
War story: <agent-name-here> dispatched a sprint at 18:00 ET via the bridge daemon...
(everything between markers ships in fleet copy; gets stripped on publish)
<!-- /[your-fleet]-private:end -->
```
*(Replace `[your-fleet]` with your fleet's name — e.g. `atlas-private`, `acme-private`, etc. Update the sanitizer regex to match.)*

Inside markers: anything goes (real agent names, real paths, real incidents). Outside markers: only generic/portable content. The post-scanner BLOCKS unmarked named-entity leaks — if you forget to wrap, publish fails loud.

**Bypass risk to know about:** if you see a BLOCK on `/tmp/SKILL.publish.md`, the correct fix is to **wrap the source in atlas-private markers** (or rephrase the source), then re-run the pipeline. Manually deleting the offending line FROM THE OUTPUT instead leaves the underlying source still leaking — next publish reintroduces the same leak. Wrap, don't delete.

**Refinement protocol:**

- **New leak class encountered?** Append a row to `$SANITIZER_DIR/rules/transforms.tsv` (auto-replace) OR `$SANITIZER_DIR/rules/deny-list.tsv` (BLOCK on detection). Rules files are append-only — never delete a rule unless it produces a verified false positive.
- **New skill ready to publish?** Drop a fixture into `$SANITIZER_DIR/test-fixtures/input/` with the leak class. If it doesn't have a corresponding `expected/` file, it becomes a scan-block test. Run `bash $SANITIZER_DIR/test-publish-sanitize.sh` before any sanitizer-rule change to confirm no regressions.
- **Sanitizer or scanner produced a false positive on something legitimate?** Refine the regex; add a fixture; rerun tests. Don't remove the rule.

**Test the pipeline before relying on it:**

```bash
bash $SANITIZER_DIR/test-publish-sanitize.sh
# Expected: all PASS. If anything fails, the sanitizer is broken — do not publish.
```

**This step is MANDATORY** for any skill that lives inside a working agent fleet and is being prepared for public publish. Real-world use on internal fleet skills confirmed the leak class is real and recurring — every fleet skill has it. The sanitizer pipeline is the durable mitigation.

## Recommended: Two-Pass Review

The checklist above catches structural issues. For a thorough review, follow it with a second pass:

1. **Pass 1** — Run through steps 1-8 above and fix everything found
2. **Pass 2** — Ask your agent to do a critical code review of the result: *"Do a thorough code review of this skill — check for factual accuracy, internal consistency between files, and anything the checklist missed."*

The second pass catches things checklists can't: factual inaccuracies in your descriptions, inconsistencies between SKILL.md and README.md, stale claims, and scope creep.

## Sustainability: Autoresearch & Self-Improvement

Published skills should be designed for autonomous improvement. Before publishing, ensure:

- [ ] **Known Limitations documented** — "Known Limitations & Gotchas" section exists with 2+ concrete constraints
- [ ] **Scoring criteria defined** — Skill includes or references how to measure "working well"
- [ ] **Category assigned** — `metadata.category` field matches the 9-category taxonomy
- [ ] **Description trigger-ready** — Description uses Intent + Constraint pattern (not just summary)
- [ ] **Success metrics identified** — If autoresearch were to improve this skill, what metric would change? (e.g., "false positive triggers", "gotcha pass rate", "end-user satisfaction")

### Autoresearch & Maintenance Plan (Optional)

If your skill is part of an autoresearch program, document the plan in a comment:

```yaml
metadata:
  autoresearch:
    frequency: "weekly"        # How often to evaluate this skill
    scoring_model: "sonnet"    # What model to use for scoring
    success_metric: "gotcha_pass_rate >= 95%"  # Definition of "working"
    review_team: "DevOps"      # Who reviews failures
```

This signals to autoresearch agents that your skill is **actively maintained** and they should invest cycles in it.

## Verification

Before pushing, validate with the official reference library:
```bash
npx skills-ref validate ./my-skill
```
See: [skills-ref](https://github.com/agentskills/agentskills/tree/main/skills-ref)

After pushing, verify on GitHub:
1. README renders correctly (tables, code blocks, links)
2. LICENSE.txt is detected by GitHub (shows license badge)
3. File structure looks clean (no .DS_Store, no stray files)
4. Clone and run: `git clone ... && node scripts/my-script.js --help`

### 10. Set repo metadata (description + homepage + topics)

Once the repo exists, set discovery metadata so the skill is findable:

```bash
# Description should LEAD WITH THE SKILL NAME, not a category prefix.
# Bad:  "AgentSkill: do X for Y" — generic; loses the skill's identity in search
# Good: "<skill-name> — do X for Y. Key features. Spec compliance."
gh repo edit <org>/<skill-name> --description "<skill-name> — <one-line what + why>"

# Homepage: clear if no real project homepage exists. Don't point at the spec
# (agentskills.io) — that's the SPEC's home, not the SKILL's home.
gh repo edit <org>/<skill-name> --homepage ""
# OR set to a real project page if you have one:
gh repo edit <org>/<skill-name> --homepage "https://<your-skill-page>"

# Topics: 4-8 tags for discovery. Standard agentskills topics + skill-specific.
gh repo edit <org>/<skill-name> --add-topic agentskills,claude-code,<topic1>,<topic2>,<topic3>
```

**Topic tag picks (canonical for fleet skills):**
- `agentskills` — for the agentskills.io ecosystem
- `claude-code` — works in Claude Code (omit if true model-agnostic)
- The skill's primary noun (e.g., `session-handoff`, `code-review`, `pre-publish`)
- The skill's category (e.g., `meta-skill`, `runbook`, `data-fetching`)
- Observability / autoresearch tag if applicable: `observability`

**Verify final state:**
```bash
gh repo view <org>/<skill-name> --json description,homepageUrl,repositoryTopics
```

**Why this matters:** spec compliance and a clean LICENSE get you to "valid skill"; description + homepage + topics get you to "discoverable skill." A published skill with an accurate description and 5+ topics shows up in GitHub search; one without is invisible.

## References

- [Agent Skills Specification](https://agentskills.io/specification)
- [skills-ref Validation Library](https://github.com/agentskills/agentskills/tree/main/skills-ref)
- [Example Skills (Anthropic)](https://github.com/anthropics/skills)
- [Creating Custom Skills (Claude)](https://support.claude.com/en/articles/12512198-creating-custom-skills)

### Sanitizer infrastructure (installed with this skill)
- `<skills-install>/publish-skills/scripts/publish-sanitize.sh` — Stage 1 sanitizer (transforms + marker stripping)
- `<skills-install>/publish-skills/scripts/post-scan.sh` — Stage 2 deny-list scanner (BLOCK / WARN severity)
- `<skills-install>/publish-skills/scripts/test-publish-sanitize.sh` — regression test suite
- `<skills-install>/publish-skills/scripts/rules/transforms.tsv` — append-only path/token transforms
- `<skills-install>/publish-skills/scripts/rules/deny-list.tsv` — append-only deny-list (severity-tagged)
- `<skills-install>/publish-skills/scripts/test-fixtures/{input,expected}/` — adversarial test corpus

---

## Autoresearch: Skill Self-Evaluation

**Baseline Score:** 10/12 (2026-03-18)  
**Target Score:** 12/12  
**Gaps to Address:** Progressive disclosure, dependency formalization

### Publish-Skills-Specific Quality Checklist

When running autoresearch iterations on this skill, use these 6 objective criteria:

1. **Frontmatter Validation:** Does the guide correctly validate SKILL.md frontmatter (name format, description length, required vs. optional fields)? Test by running against a deliberately malformed SKILL.md.
   - **Verification:** Create test skill with wrong name format (uppercase, spaces, consecutive hyphens). Checklist should catch all 3.

2. **Clone URL Accuracy:** Do all clone/install URLs in the README.md template examples point to a valid schema format? Test by extracting all URLs and verifying patterns match `https://github.com/{org}/{repo}`.
   - **Verification:** `grep -o "github.com/[^/]*/[^/]*" publish-skills/SKILL.md | sort -u` should show only valid org/repo patterns.

3. **Pre-Publish Checklist Completeness:** Are all 8 pre-publish checklist items actionable and testable? Each should have a clear verification command or manual check.
   - **Verification:** For each of the 8 items in "7. Consistency Review", confirm a user could perform it without asking for clarification.

4. **Common Mistakes Coverage:** Do the 7 common mistakes cover the actual failure modes when publishing skills? Should match real errors from published skills.
   - **Verification:** Read 3 published skills on GitHub; identify any pre-publish errors not covered in the "Common Pre-Publish Mistakes" table. If found, gaps exist.

5. **Directory Structure Prescription:** Is the recommended directory structure (SKILL.md, LICENSE.txt, README.md, scripts/, references/, assets/) clear enough that a user building a skill folder could follow it unambiguously?
   - **Verification:** Show the directory structure template to a new user building a skill. Can they build it without questions? If yes, criterion met.

6. **GitHub Verification Steps:** Are the 4 post-push verification steps (README rendering, LICENSE badge, file structure cleanliness, clone/run test) sufficient to catch 90%+ of publication issues?
   - **Verification:** Audit 5 recently-published skills. Do they all pass the 4 verification steps? Identify any issues that would have been caught by an additional verification step.

### Autoresearch Mutation Candidates

**High-priority mutations to test:**

1. **Add Progressive Disclosure Section** — Create `references/agentskills-spec.md` and `references/common-pitfalls.md`. Update SKILL.md frontmatter to reference them. Measure: reduced token count of SKILL.md body while maintaining clarity.

2. **Formalize Dependencies** — Add explicit "Dependencies" section listing `npx skills-ref` as a required tool. Add version constraints if applicable (Node.js version, npm version).

3. **Add Scripted Validation** — Create `scripts/validate-skill.sh` that runs the 8-step checklist programmatically on a target skill. Measure: can users run the checker as a one-liner vs. manual steps.

4. **Expand GitHub-Specific Verification** — Add curl/gh CLI commands to verify LICENSE detection and README rendering without manual GitHub UI interaction. Measure: reduce verification time from 5 min to <1 min.

5. **Add Example Skill Audit** — Provide a full worked example of auditing a real published skill (e.g., `anthropics/skills/my-skill`) through all 8 steps. Measure: user clarity on how to apply the checklist.

### Running Autoresearch

To improve publish-skills beyond 10/12:

```bash
# Phase 1: Define test inputs
# Test inputs: 3 pre-publication skills (one compliant, one with mistakes, one mixed)

# Phase 2: Run autoresearch loop
# Focus on mutations that reduce manual review time while maintaining coverage

# Phase 3: Target improvements
# Primary: Progressive disclosure (file system restructuring)
# Secondary: Dependency formalization
# Tertiary: Scripted validation helpers

# Success criteria: 12/12 when all 6 checklist items pass 100% consistently
```

**Notes for next auditor:**
- Consider whether this skill should be split into two: "Design Skills" (SKILL.md format) and "Publish Skills" (GitHub release process). Current blend works but boundaries are fuzzy.
- The two-pass review pattern (manual + critical code review) is strong. Don't mutate this.
- Progressive disclosure is the largest gap. Reorganizing into references/ folders would improve token efficiency.
