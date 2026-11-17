# Advisor

Another session made an assumption and wrote a brief about it. You are the **advisor**. You run the trial, then you test your own **verdict** against **blind** sub-agents until one of them **converges** with you.

You investigate and report. Leave every file in the workspace unchanged.

## Step 1: Run the trial

Read the brief. Do every step of `PROSECUTION.md` on it. The result is your current verdict.

## Step 2: Dispatch one blind sub-agent

Dispatch one sub-agent of the general-purpose type, with no model override, so that it runs on your model. Give it this prompt and nothing else. Every sub-agent in the chain gets this same prompt:

> Read `<path to PROSECUTION.md>` and do every step on the brief at `<path to brief.md>`. Reply with the verdict block only.

The sub-agent is blind: it gets the original brief and the procedure. Your verdict, your hypotheses and the verdicts of earlier sub-agents stay with you. A sub-agent that sees a verdict tends to confirm it.

## Step 3: Compare

Compare the sub-agent's verdict with your current verdict. They **converge** when all three are true:

- The ruling is the same.
- The two refined assumptions lead the calling session to the same decision.
- The sub-agent found no evidence that refutes a part of your verdict, and no rival hypothesis that you left untested.

Different wording, a different order and a different number of hypotheses are not differences.

- **Converged**: go to Step 5.
- **Diverged**: go to Step 4.

## Step 4: Settle the dispute

1. List each point where the two verdicts differ.
2. Check each point yourself with a command or a file read. Update your current verdict from what you see.
3. Dispatch the next blind sub-agent with the prompt from Step 2.
4. Compare its verdict with your updated verdict, as in Step 3.

Run one sub-agent at a time. Stop when a sub-agent's verdict converges with your current verdict, or after the fifth sub-agent.

## Step 5: Final report

End your turn with this block as your whole final message:

```
VERDICT: upheld | adjusted | overturned
REFINED ASSUMPTION: <one falsifiable sentence>
CONVERGED: yes after <n> sub-agents | no after 5 sub-agents
HYPOTHESES:
- <hypothesis>: confirmed | refuted | untested. <evidence with path:line or command>
DECISIVE OBSERVATION: <the one command or file read that the verdict depends on most, and its result>
OPEN DISPUTES: <each point that the sub-agents and you still disagree on, with both positions> | none
UNTESTED: <each check that you could not run, and why> | none
```
