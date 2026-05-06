# Project Spec: StackOverflow Tag Contributors Analytics

> This is the homework spec — written PM-style, as if a stakeholder requested
> the work. The point of this project is the wrestling, so this document
> defines the problem and acceptance criteria, not the solution.

**Repo:** `stackoverflow-analytics`
**Database:** StackOverflow2013 (~50 GB)
**Format:** Reusable analytics asset — stored procedure + supporting view
**Target effort:** 6–8 hours across 4 Thursday blocks
**Status:** Open ticket 🎫

---

## The ask (from the imaginary stakeholder)

> Hey — community team is trying to identify top contributors in specific
> technology areas. They've been doing this manually with ad-hoc queries and
> the results aren't consistent. Can you build us something we can call
> programmatically?
>
> The naive answer ("most answers in a tag") isn't useful — someone who posted
> 200 mediocre answers shouldn't beat someone who posted 30 great ones. We
> want a real picture of who's driving quality in a given technical area.
>
> Make it a stored procedure so the team can call it from their internal tools.
> The interface should be intuitive enough that a non-DBA on the team can
> figure it out from the header comment.

---

## Functional requirements

The stored procedure should accept a tag (or list of tags) and a date range,
and return ranked contributors with multiple dimensions of signal — not just
a count.

For each top contributor returned, the result should give the consumer enough
information to understand *why* they're a top contributor and *what kind* of
contributor they are. A user with 10 answers all accepted with high scores is
a different kind of contributor than someone with 100 answers with mixed
reception. Both might be valuable; the report should let the caller see which
is which.

You decide what "top contributor" means and how to combine the signals.
There are many defensible answers. Document your reasoning in the README.

---

## Parameters

Design these yourself. Things to think about as you do:

- What's the minimum viable input? (Hint: think about what defaults make the
  proc useful with no parameters at all.)
- How does the caller specify "Python" vs. "Python OR Django OR Flask"?
- How does the caller scope by time? (Open-ended? Required range? Defaults?)
- How does the caller control the size of the result? Top 10? Top 100?
- Are there any toggles a caller would reasonably want? (E.g., "include users
  who haven't been active recently?")

**Keep the interface small.** A great proc has 3–5 parameters with thoughtful
defaults. A bad one has 15 booleans.

---

## Output shape

Decide the columns yourself, but the result set should:

- Have a stable, predictable shape regardless of which parameters were passed
- Include enough columns for the consumer to sort/filter further if they want
- Have column names a non-DBA can understand without a data dictionary
- Be ordered meaningfully by default (your choice — defend it in the README)

Things that would be reasonable to surface, depending on your design:

- **Identity** — who is this contributor?
- **Volume signal** — how much have they done?
- **Quality signal** — how well-received is what they do?
- **Recency signal** — are they still active?
- **Breadth signal** — do they range, or are they specialists?
- **Trajectory signal** — rising, steady, declining?

You don't need all of these. Pick what tells a coherent story.

---

## Edge cases to handle correctly

The proc should not blow up or return misleading results in any of these
scenarios. Some are subtle.

- A tag that doesn't exist in the database
- A date range with no matching activity
- A user who has answered in the tag but their account has been deleted
- A user who has only asked questions in the tag but never answered
- A user whose answers were accepted but later deleted
- An answer with NULL score (does this happen? check)
- A user tied with another user on every metric (deterministic ordering)
- A date range that ends before it begins
- Whitespace or case mismatches in the tag parameter (`'PYTHON'` vs
  `'python'` vs `' python '`)

You may decide some of these are out of scope and document that decision.
But you should consciously decide, not accidentally miss them.

---

## Supporting view

Alongside the procedure, build at least one supporting view. A few patterns
that would make sense:

- A view that exposes "answers with their tags" in a more queryable shape
  than the raw `Posts` + `Tags` schema (the StackOverflow tag column is a
  denormalized string — that's a real annoyance to work around repeatedly)
- A view that provides per-user aggregates other procs could reuse
- A view that wraps the date-range filtering logic so it's consistent

Pick one that genuinely simplifies the procedure's body. The point is to
demonstrate factoring, not to add a view for the sake of it.

---

## Performance expectations

This is StackOverflow2013 — ~50 GB, ~17M posts, ~3M users. Your proc should:

- Return in **under 30 seconds** for typical inputs (one tag, one-year date
  range, top 50)
- Not scan the entire `Posts` table when narrower access patterns exist
- Not produce a TempDB spill in the actual execution plan

You don't need to obsess over milliseconds. But "expert-level" SQL means a
proc that's been *thought about* with respect to performance, not just one
that returns correct results given infinite time.

Note in the README what indexes you're relying on — the StackOverflow database
ships with very few, so you may need to add some.

---

## Documentation deliverables

1. **Header comment in the proc itself** — purpose, parameters, sample calls,
   any non-obvious behavior, last-updated date
2. **`README.md` in the repo** with:
   - What the proc does (one paragraph)
   - The interface (parameters, output columns, what each means)
   - 3–4 sample calls with what they'd return conceptually
   - A **"Design decisions"** section explaining choices you made and what
     you rejected (this is the section that demonstrates senior thinking —
     don't skip it)
   - Setup instructions (database, indexes you added, prerequisites)
   - Known limitations
3. **`tests-and-samples.sql`** — a file with sample calls that exercise
   different parameter combinations, including the edge cases above

---

## Acceptance criteria

This is "shippable" when:

- [ ] The proc runs against a fresh StackOverflow2013 install with documented setup
- [ ] All listed edge cases are either handled or explicitly noted in the README as out of scope
- [ ] At least one supporting view exists and is genuinely used by the proc
- [ ] Sample calls in `tests-and-samples.sql` execute without errors
- [ ] Performance target (30 seconds for typical input) is met
- [ ] README "Design decisions" section explains at least three meaningful choices you made

---

## What this project is *not*

To keep scope manageable:

- ❌ No visualization, dashboard, or Power BI layer
- ❌ No ETL — work directly against the SO2013 schema
- ❌ No ranking ML or scoring models — your "score" should be plain SQL that a stakeholder can read and understand
- ❌ No multi-language support, internationalization, or anything fancy
- ❌ Don't worry about handling 100 tags. Handling 1–5 is plenty.

---

## Suggested sequence across Thursday blocks

Just a starting point — adjust as you go:

- **Week 1 (1.5 hr):** Set up repo. Restore SO2013. Explore the schema.
  Write your first draft README — what you *think* the proc will do, before
  writing a line of SQL. Identify the indexes you'll likely need.
- **Week 2 (1.5 hr):** Build the supporting view. Get the basic shape of the
  proc working — naive version, no edge cases yet, just "does the data flow
  work?"
- **Week 3 (1.5 hr):** Layer in the multi-dimensional signal logic. Handle
  the easy edge cases.
- **Week 4 (1.5 hr):** Hard edge cases. Performance check. Polish the README.
  Write the tests file. Push, pin the repo on GitHub.

---

## How AI was used in this project

I used Claude (Anthropic's AI assistant) as a collaborator on this project,
in roles I'd describe as *product manager*, *reviewer*, and *rubber duck*.

**What Claude did:**

- Helped scope and write this spec, framed PM-style with realistic acceptance criteria
- Acted as a reviewer when I needed to sanity-check design decisions or debug my own reasoning
- Asked probing questions when I was stuck (rather than giving me answers)

**What Claude did NOT do:**

- Write the SQL — every line of T-SQL in this repo is mine
- Choose the design — interface, parameters, output shape, ranking logic, index strategy, factoring decisions are all my calls
- Resolve the hard edge cases — the wrestling was the point of the project

This is how I work with AI in a job context: as a thinking partner that sharpens
my own decisions, not as a substitute for them. The skill is knowing which parts
to delegate and which to keep — and being honest about the line.

The fuller treatment of this lives in the project README.

---

## Working notes

*(Use this section as a scratch pad while you work. Cross things out, leave
breadcrumbs to yourself, capture decisions and the reasoning behind them.
This becomes raw material for the "Design decisions" section of the README.)*

- [ ] First decision: …
- [ ] Open question: …
- [ ] Tried and rejected: FK will be complicated
