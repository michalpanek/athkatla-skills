---
name: verify-assumption
description: Put an assumption from this session on trial in a fresh advisor session on a model that you choose, then report the verdict.
argument-hint: "[optional: model] [optional: the assumption]"
disable-model-invocation: true
---

# verify-assumption

This session made an assumption. A fresh **advisor** session puts that assumption on trial as a **prosecutor**, and a chain of **blind** sub-agents repeats the trial until a verdict **converges** with the advisor's. You open the advisor, wait, and report its **verdict** to the user.

The advisor knows only the **brief** that you write. The files `ADVISOR.md` and `PROSECUTION.md` in this skill's directory are for the advisor. Give the advisor their paths and leave them unread.

## Step 1: Fix the assumption

Read `$ARGUMENTS`. A first word that names a model (an alias such as `opus`, or a full model ID) is the advisor's model. The remaining text is the assumption.

When the arguments carry no assumption, take the most recent assumption in this conversation that a decision depends on. When two or more candidates exist, show them as a numbered list and ask the user to select one.

Write the assumption as one falsifiable sentence. Show the sentence to the user.

Done when: one sentence exists, and one observation could prove it false.

## Step 2: Write the brief

Make a directory with `mktemp -d`. Write `brief.md` there as a neutral case file:

- **Assumption**: the sentence from Step 1.
- **Decision**: what this session will do if the assumption holds, and what it will do if the assumption fails.
- **Observations**: each fact that you saw, with its source (`path:line`, or the exact command and its output).
- **Inferences**: each conclusion that you drew from the observations. Keep these apart from the observations.
- **Unchecked**: each thing that you did not check.
- **Workspace**: the absolute working directory.

The brief gives the facts and their sources. Your confidence and your preferred answer stay out of it, so the advisor reaches its own answer.

Done when: a reader with no access to this conversation can repeat every observation from the brief alone.

## Step 3: Open the advisor

The advisor prompt is:

> Read `<skill dir>/ADVISOR.md` and do what it says. The brief is `<absolute path to brief.md>`. The trial procedure is `<skill dir>/PROSECUTION.md`.

Use absolute paths. Use the model from Step 1. When Step 1 gave no model, omit `--model`, so the advisor runs on the default model.

- **Inside Herdr** (`HERDR_ENV=1`): follow the `herdr` skill. Split the current pane to the right, with the same working directory and without a change of focus. Start a `claude` agent named `assumption-advisor` in the new pane (add a number when a live agent has that name), and pass `--model <model>` as a native agent argument. Send the advisor prompt and wait for a settled state with a timeout of 30 minutes.
- **Outside Herdr**: run `claude -p --model <model> "<advisor prompt>"` in the background and wait for it to exit.

When the advisor is `blocked` on an approval or a question, tell the user which pane waits for them. The user answers it.

Done when: the advisor session ended its turn with a final report that starts with `VERDICT:`.

## Step 4: Report the verdict

Read the final report from the pane, or from the output of `claude -p`. Tell the user:

- **Ruling**: `upheld`, `adjusted` or `overturned`, and the refined assumption next to the original sentence.
- **Investigation**: each hypothesis with its result and its evidence.
- **Corrections**: each part of the original assumption that the verdict changes, and each earlier conclusion or change in this session that depends on that part.
- **Confidence**: how many sub-agents ran, whether the verdicts converged, each open dispute, and each untested check.

The report ends this skill. The user decides what to do with the verdict. Leave the advisor pane open for the user.
