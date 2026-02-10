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

## File Structure

```
publish-skills/
├── SKILL.md          # Checklist (agents read this)
├── LICENSE.txt       # MIT license
├── README.md         # This file
└── .gitignore
```

## License

MIT
