---
name: publish-skills
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

## Recommended: Two-Pass Review

The checklist above catches structural issues. For a thorough review, follow it with a second pass:

1. **Pass 1** — Run through steps 1-8 above and fix everything found
2. **Pass 2** — Ask your agent to do a critical code review of the result: *"Do a thorough code review of this skill — check for factual accuracy, internal consistency between files, and anything the checklist missed."*

The second pass catches things checklists can't: factual inaccuracies in your descriptions, inconsistencies between SKILL.md and README.md, stale claims, and scope creep.

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

## References

- [Agent Skills Specification](https://agentskills.io/specification)
- [skills-ref Validation Library](https://github.com/agentskills/agentskills/tree/main/skills-ref)
- [Example Skills (Anthropic)](https://github.com/anthropics/skills)
- [Creating Custom Skills (Claude)](https://support.claude.com/en/articles/12512198-creating-custom-skills)
