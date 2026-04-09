---
title: Ecosystem Radar
description: Curated external repos and resources that are on our radar, with explicit non-endorsement and due-diligence rules.
---

## Ecosystem Radar

This page is a curated radar, not an endorsement list.

We link to outside repos, tools, and experiments because they are interesting,
useful, adjacent, or worth stealing ideas from. Once you leave this repo, we
cannot vouch for the safety, stability, licensing drift, maintenance quality,
or runtime behavior of what you find there.

Treat every external link here as:

- worth a look
- not a guarantee
- subject to change without notice
- something you should review before you run, copy, or trust

## Why This Exists

Good ecosystem awareness is part of good methodology work.

Sometimes the useful move is:

- study another repo's information architecture
- borrow a pattern
- compare approaches
- watch where a fast-moving idea is heading

What we do not want is for all of those links to live as random bookmarks in
maintainer heads or chat history.

## Common GitHub Patterns

Most projects that do this use one or more of four patterns:

1. **Awesome-style curated list**: a categorized README or doc page of links
2. **Related projects section**: a short list in the root README
3. **Ecosystem or resources page**: a deeper doc with categories, notes, and
   contribution rules
4. **Ideas or discussions queue**: a place for the community to suggest links
   without pretending every suggestion is already vetted

For this repo, the best fit is an ecosystem page plus selective README links.

## Radar Status

Use one of these statuses for entries:

- **Watching**: interesting enough to track, not yet reviewed deeply
- **Tested**: we looked at it directly and can say something concrete
- **Pattern source**: valuable mainly because of its structure or methodology
- **Adjacent**: relevant enough to keep nearby, but not central to this repo
- **Graduated**: the idea has been absorbed into merge-2-main docs or templates

## Entry Format

Each entry should stay compact and include:

- name and link
- status
- why it matters
- what caught our eye
- caution note when needed

If the repo has a meaningful license posture or obvious risk surface, call that
out too.

## On Radar

### LLM Wiki

- Link: [kothari-nikunj/llm-wiki](https://github.com/kothari-nikunj/llm-wiki)
- Status: **Adjacent**
- Why it matters: an opinionated personal-knowledge workflow that uses local
  files, markdown output, and an AI-assisted compilation step instead of a
  closed app surface
- What caught our eye: strong "file over app" posture, clean three-layer model
  (`data/`, compiled wiki, viewer), and a visible skill-driven ingestion model
- Caution: this is a different product shape than merge-2-main. It is more
  about personal knowledge compilation than multi-agent coding governance

### Awesome

- Link: [sindresorhus/awesome](https://github.com/sindresorhus/awesome)
- Status: **Pattern source**
- Why it matters: the canonical GitHub pattern for curated ecosystem links
- What caught our eye: clear categorization, contribution norms, and the fact
  that the list itself is the product
- Caution: a giant awesome-style list can sprawl quickly if entry rules are not
  tight

## Contribution Rule

If you want to add a repo here, prefer this shape:

```text
- Link: https://github.com/<owner>/<repo>
- Status: Watching | Tested | Pattern source | Adjacent | Graduated
- Why it matters: <one sentence>
- What caught our eye: <one sentence>
- Caution: <optional one sentence>
```

Good additions are:

- relevant to agentic coding, governance, review, observability, safety, or
  adjacent interface design
- interesting for pattern extraction, not just hype
- still maintained enough to be worth another person's time

Bad additions are:

- random bookmark dumps
- affiliate-style promotion
- links we cannot explain

## Current Rule

If an external repo becomes important enough to shape merge-2-main directly,
one of two things should happen next:

1. add a source-backed note about what we learned
2. graduate the pattern into a real guide, reference, or template here

The radar is the parking lot, not the final home.
