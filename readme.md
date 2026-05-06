# StackOverflow Tag Contributors Analytics

A reusable analytics asset (stored procedure + supporting view) for identifying
top contributors in technical areas of the StackOverflow community.

Built against the public StackOverflow2013 sample database.

> **Status:** in progress. See [`SPEC.md`](./SPEC.md) for the original
> requirements and acceptance criteria.

---

## What this does

*[One paragraph describing the proc once it's built. To be filled in.]*

## Setup

*[Database restore, indexes added, prerequisites. To be filled in.]*

## The interface

### Stored procedure: `dbo.usp_TagTopContributors` *(working name)*

*[Parameter table — name, type, default, description. To be filled in.]*

### Supporting view(s)

*[What the view exposes and why. To be filled in.]*

### Output columns

*[Column-by-column documentation a non-DBA could understand. To be filled in.]*

## Sample calls

```sql
-- 3–4 representative calls showing typical usage and edge cases.
-- To be filled in.
```

## Design decisions

*[The senior-thinking section. Choices made, alternatives considered and rejected,
and the reasoning. To be filled in as the project progresses.]*

- **What "top contributor" means in this proc:** *[TBD]*
- **Why this parameter shape:** *[TBD]*
- **Why a view here:** *[TBD]*
- **Performance trade-offs:** *[TBD]*

## Known limitations

*[Things explicitly out of scope, edge cases not handled, future v2 work. To be filled in.]*

## Testing

See [`tests-and-samples.sql`](./tests-and-samples.sql) for sample calls
exercising parameter combinations and edge cases.

---

## How AI was used in this project

I used Claude (Anthropic's AI assistant) as a collaborator on this project,
in roles I'd describe as *product manager*, *reviewer*, and *rubber duck*.
This README is the long version of the short note in [`SPEC.md`](./SPEC.md);
the short version is: **the SQL is mine, the wrestling was mine, the design
decisions are mine. AI sharpened the work; it didn't do the work.**

### What Claude did

- **Wrote the spec.** I told Claude what I wanted to practice (expert-level
  T-SQL on a reusable analytics asset against StackOverflow data) and we
  iterated on the framing. The result is `SPEC.md` — written PM-style, as if
  a real stakeholder filed the ticket. The framing forced me to treat this
  like a real deliverable, not a learning exercise.
- **Acted as a reviewer.** When I needed to sanity-check a design decision —
  *"should this be a view or a CTE inside the proc?"*, *"is this parameter
  shape too clever?"* — Claude pushed back on weak choices and validated
  strong ones. Critically, Claude was instructed to **ask me questions**
  rather than give me answers, so the conclusions stayed mine.
- **Was a rubber duck for stuck moments.** When I hit something I couldn't
  see through, explaining the problem out loud (to Claude) often got me
  unstuck before Claude had to say anything substantive — which is the
  classic value of a rubber duck.

### What Claude did NOT do

- **Write the SQL.** Every line of T-SQL in this repository is mine. Claude
  was explicitly instructed not to give me code or even hint at which
  features/functions to use.
- **Make the design decisions.** Interface shape, parameter defaults, output
  columns, ranking logic, factoring choices, index strategy — these are all
  my calls. The "Design decisions" section above documents the reasoning,
  and the reasoning is mine.
- **Handle the hard edge cases.** Wrestling with the messy parts (deleted
  users, NULL scores, ambiguous tag inputs, ties in ranking) was the point
  of the exercise. Claude could clarify the spec but wouldn't tell me how
  to resolve the ambiguity.

### Why I'm explicit about this

In 2026, the question isn't whether candidates use AI tools — most do. The
question is *how thoughtfully*. I think the honest answer is more credible
than either pretending I didn't use AI or quietly outsourcing the thinking
to it. The skill I want to demonstrate isn't "I can produce SQL" — it's "I
can design an analytics asset, defend my choices, and use available tools
(including AI) to sharpen rather than replace my own judgment."

If you're a hiring manager reading this and you'd like to ask about my
process — what I delegated, what I kept, where I'd draw the line differently
on a different project — I'd genuinely enjoy that conversation.

---

## License

MIT — see [`LICENSE`](./LICENSE).
