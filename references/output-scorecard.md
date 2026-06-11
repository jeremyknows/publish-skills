# Publish-Skills Output Scorecard

Run on any skill directory after a publish-skills audit. YES/NO answers, no judgment calls. Pass = 9/10 minimum, with all "structural" items YES.

## Structural (must all be YES)

1. **SKILL.md exists with valid frontmatter** — `head -1 SKILL.md` returns `---` and `name:` + `description:` fields are present.
2. **Skill name matches directory** — frontmatter `name:` value equals `basename $(pwd)`.
3. **LICENSE.txt present** — `test -f LICENSE.txt` succeeds and contains a recognized license body.
4. **README.md present** — `test -f README.md` succeeds and is non-empty.
5. **.gitignore present and includes `.DS_Store`** — `grep -q '.DS_Store' .gitignore` succeeds.

## Content (must all be YES)

6. **Description ≤ 1024 chars** — `awk '/^description:/,/^[a-z-]+:/' SKILL.md | wc -c` under 1024.
7. **No leading/trailing/consecutive hyphens in name** — name passes `^[a-z0-9]+(-[a-z0-9]+)*$`.
8. **All clone URLs in README point to one consistent org/repo** — `grep -oE 'github.com/[^ )]+' README.md | sort -u` returns one canonical repo per platform section.

## Hygiene (must both be YES)

9. **No personal paths or usernames** — `grep -iE '/Users/|/home/[a-z]+|@gmail\.com|@icloud\.com' SKILL.md README.md` returns nothing.
10. **LICENSE year and copyright holder match repo owner** — open LICENSE.txt and confirm year is current and holder matches the publishing org/user.

## Run

```bash
cd path/to/skill
# Structural sweep
test -f SKILL.md && test -f LICENSE.txt && test -f README.md && grep -q '.DS_Store' .gitignore && echo "structural: pass"
# Name check
NAME=$(awk '/^name:/{print $2; exit}' SKILL.md)
DIR=$(basename $(pwd))
[ "$NAME" = "$DIR" ] && echo "name match: pass"
# Personal data sweep
grep -iE '/Users/|/home/[a-z]+|@gmail\.com|@icloud\.com' SKILL.md README.md && echo "FAIL: personal data" || echo "personal data: clean"
```

## Pass/fail

- All 5 Structural + all 3 Content + both Hygiene = pass, ready to push
- Any Structural fail = block the commit
- Content fail = fix before push
- Hygiene fail = scrub before push, then re-run

If passing rate across 5+ skill audits is ≥80%, the skill is empirically validated (Q13 in the skill-doctor checklist).
