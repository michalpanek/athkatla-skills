---
name: spade-it
description: Facilitate a full S.P.A.D.E. decision session — Setting, People, Alternatives, Decide, Explain.
disable-model-invocation: true
---

# spade-it

Facilitate a full S.P.A.D.E. session with the user, one phase at a time. S.P.A.D.E. (Setting, People, Alternatives, Decide, Explain) is a framework built at Square for hard decisions where ownership, transparency, and follow-through matter.

**Mode**: interactive. Work through each phase in sequence, surface gaps, push on vague answers, then produce the final document.

---

## Before starting

SPADE is for **hard decisions only** — consequential, non-obvious, and contested. Quick or low-stakes calls don't need SPADE; they need a default and a DRI. If the decision is trivial, say so and stop.

If the user hasn't named a decision, ask for it before proceeding.

---

## Phase S — Setting

Help the user define three dimensions precisely. Don't accept vague answers.

**What** — The exact decision, with all its axes. "Which vendor to pick" is weak. "Which ATS to run for the next three years, optimizing for functionality and switching cost" is precise. Push until there is zero ambiguity about what is being chosen.

**When** — The exact deadline plus the reasoning chain behind it. Deadlines without logic breed resistance. Surface the chain: "Decision by Oct 15 because the launch is Nov 15 and collateral needs 4 weeks." The *why* of the *when* matters as much as the date itself.

**Why** — The optimization goal. What does the right decision maximize for? This is the conflict resolver: when two alternatives look equally good, the Why breaks the tie. Misaligned Whys cause the loudest organizational fights.

Completion criterion: all three answered concretely with no hand-waving. If any dimension is still vague, push back — don't move to Phase P.

---

## Phase P — People

Three roles. One DRI. Never a committee.

**Responsible (DRI)** — Owns both the decision and its execution. Accountability and responsibility are the same person in SPADE — whoever decides, executes. There is no handoff after the decision is made. This is what separates SPADE from consensus.

**Approver** — Can veto, but should be invoked sparingly. One Approver only. If the user names more than one, flag it: multiple Approvers recreate the consensus problem.

**Consulted** — Everyone whose input should be gathered before deciding. Default to more than feels comfortable — under-consulting is the most common SPADE failure mode. Consulted people give input; they don't vote (voting happens privately in Phase D).

Completion criterion: DRI named, one Approver named, Consulted list actively considered beyond the obvious names.

---

## Phase A — Alternatives

Generate a set of options that is feasible, diverse, and comprehensive.

- **Feasible**: Each option is actually doable given real constraints.
- **Diverse**: Genuinely different directions, not micro-variants of one path.
- **Comprehensive**: The set covers the problem space. Always consider "status quo / do nothing" as an option.

For each alternative, develop:
- Pros (with quantitative impact estimates where possible — rough numbers beat gut feel)
- Cons (cost, risk, switching cost, opportunity cost)

Brainstorming should happen publicly with the Consulted group. The DRI curates the final shortlist.

Completion criterion: at least 3 distinct alternatives documented, each with pros/cons. User has actively checked whether an obvious option is missing.

---

## Phase D — Decide

Consultants vote **privately** before the DRI decides. Private voting is non-negotiable — public votes collapse into hierarchy and groupthink, which is the exact failure SPADE is designed to avoid.

Once all votes and reasoning are collected, the DRI:

1. Reviews all input
2. Weighs alternatives against the optimization goal from Setting (the Why)
3. Picks one option
4. Writes the rationale in one paragraph: what was chosen, what was deprioritized, and why

Completion criterion: single option chosen, one-paragraph rationale written. No hedging, no "let's revisit in a week."

---

## Phase E — Explain

Three actions, in order:

**Approver presentation** — Present the full SPADE to the Approver: alternatives, votes, and rationale. A well-constructed SPADE is rarely vetoed here because the work is visible and the reasoning is sound.

**Commitment meeting** — Bring all Consulted together. Announce the decision. Go around the room and have each person say aloud whether they agree or disagree. Verbal commitment in the presence of peers — what Andy Grove called a commitment meeting — dramatically increases follow-through. People who disagree can say so; they just commit to executing anyway.

**Broadcast and log** — Send a one-page summary of the SPADE to the widest appropriate audience. Archive it with a date. Transparency about how decisions are made builds as much organizational trust as the decisions themselves.

Completion criterion: summary drafted, audience identified, archive entry ready.

---

## Final output

After all phases are complete, produce the full SPADE document:

```
SETTING
What:   [precise decision with all axes]
When:   [exact date] — because [reasoning chain]
Why:    [optimization goal]

PEOPLE
Responsible (DRI):  [name / role]
Approver:           [name / role]
Consulted:          [names / roles]

ALTERNATIVES
[Option A — name]
  Pros: ...
  Cons: ...

[Option B — name]
  Pros: ...
  Cons: ...

[Option C — name]
  Pros: ...
  Cons: ...

DECIDE
Decision:  [chosen option]
Rationale: [one paragraph — what was chosen, what was deprioritized, why]

EXPLAIN
Approver presentation:  [status / date]
Commitment meeting:     [when / attendees]
Broadcast:              [to whom / channel]
Log:                    [location / date]
```
