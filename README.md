# publish-skills

Pre-publish checklist for [Agent Skills](https://agentskills.io) — the open standard for agent capabilities supported by [Claude Code](https://code.claude.com), [Cursor](https://cursor.com), [Gemini CLI](https://geminicli.com), and [many more](https://agentskills.io). Makes sure your skill is spec-compliant and GitHub-ready before you ship.

## How skills work

Agent Skills are folders containing a `SKILL.md` file with YAML frontmatter and markdown instructions. When you install a skill into your agent's skills directory, the agent reads the frontmatter to decide when the skill is relevant, then loads the instructions on demand. No runtime, no build step — just structured markdown that agents know how to find and use.

## What it does

Bridges the gap between "works locally" and "ready for open source." The Agent Skills spec only requires `name` + `description`, but most published skills ship with more. This checklist covers everything the spec doesn't tell you.

- **Frontmatter audit** — required, should-have, and optional fields
- **Name validation** — the exact rules (no consecutive hyphens, must match directory, etc.)
- **Directory structure** — what files to include and why
- **README patterns** — section-by-section guide based on well-received published skills
- **Consistency review** — 10-point checklist for catching pre-publish mistakes
- **Common mistakes table** — what goes wrong and how to detect it
- **Sanitizer pipeline** — for fleet skills with private context: strip internal paths, agent names, and war stories before publishing; defend with a deny-list scanner for credentials and residual leaks

## Install

### Claude Code

```bash
mkdir -p .claude/skills
cd .claude/skills
git clone https://github.com/jeremyknows/publish-skills.git
```

### Cursor / Other agents

```bash
# Check your agent's docs for the skills directory location, then:
git clone https://github.com/jeremyknows/publish-skills.git
```

### OpenClaw

```bash
cd ~/.openclaw/skills
git clone https://github.com/jeremyknows/publish-skills.git
```

## Usage

### Natural language

Just ask your agent:

- "Is this skill ready to publish?"
- "Review my skill for spec compliance"
- "What am I missing before I push this skill to GitHub?"
- "Audit this skill against the Agent Skills spec"

### As a checklist

The SKILL.md contains a numbered checklist you can work through:

1. SKILL.md frontmatter (required + should-have fields)
2. Name validation rules
3. Directory structure
4. SKILL.md body (token count, progressive disclosure)
5. LICENSE.txt
6. README.md patterns
7. Consistency review (10 checks)
8. Common pre-publish mistakes

### Recommended workflow: two-pass review

We found the most effective approach is a **two-pass review**:

1. **Pass 1 — Checklist audit**: Ask your agent to run through this skill's checklist against your skill. This catches structural issues (missing files, bad frontmatter, name mismatches).

2. **Pass 2 — Critical code review**: After fixing Pass 1 issues, ask your agent to do a thorough code review of the result. This catches factual inaccuracies, inconsistencies between files, and things the checklist doesn't cover (like whether your description accurately reflects what the skill does).

Example prompts for Pass 2:
- "Now do a thorough code review of the skill — check for factual accuracy, internal consistency, and anything the checklist might have missed"
- "Review all files in my-skill/ for pre-publish issues"

This two-pass approach caught 6 factual inaccuracies in our own skill that the checklist alone missed.

## Why this exists

We built this after publishing [openclaw-bridge](https://github.com/jeremyknows/openclaw-bridge) and realizing the gap between "valid skill" and "polished open source skill" required research across three sources:

- [Agent Skills Specification](https://agentskills.io/specification)
- [Anthropic's official skills repo](https://github.com/anthropics/skills)
- Published community skills (README patterns, structure conventions)

This skill distills that research into a single actionable checklist.

## What this doesn't cover

This skill focuses on **getting a working skill ready for GitHub**. It does not cover:

- **Writing the skill itself** — how to structure instructions, choose trigger conditions, or write effective descriptions
- **Runtime validation** — use [`skills-ref validate`](https://github.com/agentskills/agentskills/tree/main/skills-ref) for automated spec validation
- **Marketplace publishing** — the Claude Code plugin marketplace (`.claude-plugin` format) is a separate distribution channel with its own requirements
- **Skill discovery** — how agents find and select skills at runtime

## Sanitizer Pipeline Setup

If your skill lives inside a working agent fleet (internal paths, agent names, war stories), use the included sanitizer pipeline to emit a clean publishable copy without touching the source.

### 1. Configure your fleet paths (`scripts/rules/transforms.tsv`)

Open `scripts/rules/transforms.tsv` and add a row for each internal path you want to transform:

```
~/myfleet/shared/scripts/	<fleet-scripts>/	fleet shared scripts
~/myfleet/agents/	<workspace>/agents/	fleet agent workspaces
/Users/myusername/	<home>/	user home path
```

Format: `<sed-pattern>\t<replacement>\t<comment>`. Rules are applied in order — put longer paths before shorter ones.

### 2. Configure your deny-list (`scripts/rules/deny-list.tsv`)

Open `scripts/rules/deny-list.tsv` and add BLOCK rows for your fleet's agent names and internal tooling:

```
BLOCK	\b(AgentOne|AgentTwo)\b	fleet-agent-name	Wrap in fleet-private markers or replace with <agent>
BLOCK	~/myfleet/	fleet-path	Add to transforms.tsv instead, or wrap in markers
```

The credential-leak rules (API keys, tokens, PEM keys) are already included and apply universally — don't remove them.

### 3. Mark private content in your source

Wrap fleet-internal content with marker comments. The sanitizer strips everything between them:

```markdown
<!-- [your-fleet]-private:start -->
Internal war story, real agent names, private paths — anything fleet-specific.
<!-- /[your-fleet]-private:end -->
```

Set `FLEET_MARKER` to your prefix (default: `atlas-private`):

```bash
# Use the default (atlas-private):
bash scripts/publish-sanitize.sh path/to/SKILL.md /tmp/SKILL.publish.md

# Or specify your own prefix:
FLEET_MARKER=myfleet-private bash scripts/publish-sanitize.sh path/to/SKILL.md /tmp/SKILL.publish.md
```

### 4. Run the pipeline

```bash
# Stage 1: strip private blocks + apply transforms
bash scripts/publish-sanitize.sh path/to/SKILL.md /tmp/SKILL.publish.md

# Stage 2: deny-list scan (BLOCK = publish forbidden)
bash scripts/post-scan.sh /tmp/SKILL.publish.md

# Stage 3: manual diff — review every removal
diff -u path/to/SKILL.md /tmp/SKILL.publish.md | less

# Then copy the output to your public repo
cp /tmp/SKILL.publish.md path/to/public-repo/SKILL.md
```

### 5. Run the test suite

```bash
bash scripts/test-publish-sanitize.sh
# Expected: all PASS
```

Add your own fixtures to `scripts/test-fixtures/input/` — if there's a matching `expected/` file it becomes a transform test; without one it becomes a scan-block test.

---

## File Structure

```
publish-skills/
├── SKILL.md                        # Checklist (agents read this)
├── LICENSE.txt                     # MIT license
├── README.md                       # This file
├── .gitignore
└── scripts/
    ├── publish-sanitize.sh         # Stage 1: strip private blocks + apply transforms
    ├── post-scan.sh                # Stage 2: deny-list scanner (BLOCK/WARN)
    ├── test-publish-sanitize.sh    # Test suite
    ├── rules/
    │   ├── transforms.tsv          # Path/token transform rules (customize for your fleet)
    │   └── deny-list.tsv           # Credential + fleet-leak rules (customize + extend)
    └── test-fixtures/
        ├── input/                  # Test input files
        └── expected/               # Expected transform outputs (scan-block tests have no expected file)
```

## License

MIT
