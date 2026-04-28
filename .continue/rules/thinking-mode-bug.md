---
description: Clarifies model behavior in Thinking mode while supporting multiple tool calls
---

<thinking_mode_rule>
While in Thinking mode, you cannot invoke tools.
When you invoke tools, **you will be automatically put into thinking mode**.
If you do not intend to think, you **MUST** exit Thinking mode before executing tasks.
Always wait for tool output to be injected into the conversation before resuming reasoning.  
You may invoke multiple tools, but do so one at a time:
- Call a tool
- Exit Thinking mode
- Process its output
- Then, if needed, invoke the next tool
</thinking_mode_rule>
