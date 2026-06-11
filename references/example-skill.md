# Worked Example: Publishing a Skill

Concrete walkthrough of taking a working local skill (`weather-lookup`) from "works on my machine" to "ready to push to GitHub."

## Starting state

```
~/.claude/skills/weather-lookup/
├── SKILL.md
└── scripts/
    └── fetch.sh
```

`SKILL.md` (before):

```yaml
---
name: weather-lookup
description: Looks up the weather for a given city using the OpenWeather API.
---

# Weather Lookup

Fetches current conditions from OpenWeather. Set `OPENWEATHER_API_KEY` in env.

Run: `bash scripts/fetch.sh <city>`
```

## Pass 1 — Run the checklist

| Step | Issue found | Fix |
|------|-------------|-----|
| 1. Frontmatter | Missing `license` and `metadata` | Add `license: MIT`, `metadata: {author: jdoe, version: "1.0.0"}` |
| 2. Name | OK — matches directory | — |
| 3. Directory | Missing LICENSE.txt, README.md, .gitignore | Add all three |
| 4. SKILL.md body | No prerequisites, no troubleshooting | Add sections |
| 5. LICENSE.txt | Missing | Drop in MIT, year 2026, holder "Jane Doe" |
| 6. README.md | Missing | Use the section template (What it does / Install / Setup / Usage / Configuration / Limitations) |
| 7. Consistency | `scripts/fetch.sh` uses relative path; README says full path | Pick one. Standardize on `~/.claude/skills/weather-lookup/scripts/fetch.sh` |
| 8. Common mistakes | Description doesn't say *when* to use | Rewrite as trigger conditions |

## Final state

```
~/.claude/skills/weather-lookup/
├── SKILL.md          # frontmatter + body, ~80 lines
├── LICENSE.txt        # MIT, 2026, Jane Doe
├── README.md          # GitHub-facing docs
├── .gitignore         # .DS_Store, node_modules/
└── scripts/
    └── fetch.sh       # chmod +x, uses absolute paths in echo'd help
```

`SKILL.md` (after, frontmatter):

```yaml
---
name: weather-lookup
description: |
  Look up current weather conditions for a city.
  Use when: (1) user asks for weather in a specific city,
  (2) building a script that needs ambient weather data,
  (3) checking conditions before scheduling outdoor work.
  NOT for: forecasts, historical data, or air quality.
license: MIT
metadata:
  author: jdoe
  version: "1.0.0"
compatibility: Requires bash, curl, and an OpenWeather API key
---
```

## Pass 2 — Critical review

After Pass 1 fixes, ran `claude` with prompt:
> "Review weather-lookup/ for factual accuracy and internal consistency."

Caught:
- README claimed support for "all major cities worldwide" but `fetch.sh` only handles ASCII city names. Fixed by adding a Limitations section: "ASCII city names only; Unicode names need URL-encoding which is not yet handled."
- SKILL.md said "set `OPENWEATHER_API_KEY`" but README setup section forgot to mention it. Added to Setup step 2.

## Verification

```bash
cd ~/.claude/skills/weather-lookup
npx skills-ref validate .                  # spec compliance
bash scripts/fetch.sh Toronto              # smoke test
git status                                  # clean tree
git log --format="%an <%ae>" -1            # correct author
```

All four pass. Ready to push.

## Output template

When this skill is invoked on another skill, the agent should produce:

```markdown
# Pre-Publish Audit: <skill-name>

## Frontmatter
- [ ] Required fields present: name, description
- [ ] Should-have fields: license, metadata
- [ ] Description under 1024 chars and reads as trigger conditions

## Files
- [ ] SKILL.md
- [ ] LICENSE.txt (year + holder verified)
- [ ] README.md (sections: What it does, Install, Usage, Limitations)
- [ ] .gitignore (includes .DS_Store)

## Issues found
1. <one-line description> — fix: <action>
2. ...

## Verdict
- READY / NEEDS FIXES / BLOCKED
- If NEEDS FIXES: list the blocking items
```
