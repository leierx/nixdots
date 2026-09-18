import { Type, type Static } from "typebox";

const CANCELLED = "User cancelled the question. Stop and wait for further instructions.";
const NO_UI =
  "ask_user is unavailable in non-interactive mode; ask in plain text at the end of your reply instead.";
const OTHER = "Other (type an answer)";

const Params = Type.Object({
  questions: Type.Array(
    Type.Object({
      question: Type.String({ description: "The question to ask" }),
      options: Type.Optional(
        Type.Array(
          Type.Object({
            label: Type.String({ description: "Short label for the choice" }),
            description: Type.Optional(
              Type.String({ description: "One-line explanation shown with the label" }),
            ),
          }),
          {
            minItems: 2,
            maxItems: 6,
            description: "Choices to offer. Omit to ask for free text.",
          },
        ),
      ),
      multiSelect: Type.Optional(
        Type.Boolean({ description: "Allow picking more than one choice (default false)" }),
      ),
    }),
    { minItems: 1, maxItems: 4, description: "Questions to ask, in order" },
  ),
});

type Answer = {
  question: string;
  answer: string;
};

type DialogOptions = {
  signal?: AbortSignal;
};

type Ctx = {
  hasUI: boolean;
  ui: {
    select(title: string, options: string[], opts?: DialogOptions): Promise<string | undefined>;
    editor(title: string, prefill?: string): Promise<string | undefined>;
    notify(message: string, type?: "info" | "warning" | "error"): void;
  };
};

type ToolResult = {
  content: { type: "text"; text: string }[];
  details: { answers: Answer[]; cancelled: boolean };
};

type ToolUpdate = (partialResult: ToolResult) => void;

type Registry = {
  registerTool(tool: {
    name: string;
    label: string;
    description: string;
    promptSnippet?: string;
    promptGuidelines?: string[];
    parameters: typeof Params;
    executionMode?: "sequential" | "parallel";
    execute(
      toolCallId: string,
      params: Static<typeof Params>,
      signal: AbortSignal | undefined,
      onUpdate: ToolUpdate | undefined,
      ctx: Ctx,
    ): Promise<ToolResult>;
  }): void;
};

function result(text: string, answers: Answer[], cancelled = false): ToolResult {
  return {
    content: [{ type: "text", text }],
    details: { answers, cancelled },
  };
}

function formatAnswers(answers: Answer[]) {
  return answers.map((a) => `Q: ${a.question} -> A: ${a.answer}`).join("\n");
}

function toggle(values: string[], value: string) {
  const index = values.indexOf(value);
  if (index === -1) values.push(value);
  else values.splice(index, 1);
}

export default function askUser(pi: Registry) {
  pi.registerTool({
    name: "ask_user",
    label: "Ask User",
    description:
      "Ask the user a question and get the answer through an interactive picker, instead of guessing. Use it when a decision is genuinely the user's — scope, naming, trade-offs, destructive or irreversible steps — and cannot be answered by reading code or running commands. Do not use it to ask permission for routine work. Offer options where you can, with the recommended choice first.",
    promptSnippet: "Ask the user to pick between options or type an answer",
    promptGuidelines: [
      "Use ask_user when a decision belongs to the user and cannot be resolved from the code or by running commands.",
    ],
    parameters: Params,
    executionMode: "sequential",

    async execute(_toolCallId, params, signal, _onUpdate, ctx) {
      if (!ctx.hasUI) return result(NO_UI, []);

      const dialogOptions = { signal };
      const answers: Answer[] = [];

      // editor() is the multi-line prompt: Ctrl+J/Shift+Enter add lines, Ctrl+G opens $EDITOR.
      const askText = async (question: string) => (await ctx.ui.editor(question))?.trim();

      const cancelResult = () =>
        result(
          answers.length === 0
            ? CANCELLED
            : `${CANCELLED}\n\nAlready answered:\n${formatAnswers(answers)}`,
          answers,
          true,
        );

      for (const { question, options, multiSelect } of params.questions) {
        ctx.ui.notify(`Waiting for your answer: ${question}`, "info");

        if (options === undefined || options.length === 0) {
          const typed = await askText(question);
          if (typed === undefined) return cancelResult();
          answers.push({ question, answer: typed || "(no answer)" });
          continue;
        }

        const displays = options.map((option) =>
          option.description ? `${option.label} — ${option.description}` : option.label,
        );
        let other = OTHER;
        while (displays.includes(other)) other += " ";
        const entries = [...displays, other];

        if (multiSelect !== true) {
          const choice = await ctx.ui.select(question, entries, dialogOptions);
          if (choice === undefined) return cancelResult();
          const index = entries.indexOf(choice);
          if (index < displays.length) {
            answers.push({ question, answer: options[index].label });
            continue;
          }
          const typed = await askText(question);
          if (typed === undefined) return cancelResult();
          answers.push({ question, answer: typed || "(no answer)" });
          continue;
        }

        const picked: string[] = [];
        let done = "Done";
        while (entries.includes(done)) done += " ";
        const list = [...entries, done];
        for (;;) {
          const title =
            picked.length === 0 ? question : `${question} (selected: ${picked.join(", ")})`;
          const choice = await ctx.ui.select(title, list, dialogOptions);
          if (choice === undefined) return cancelResult();
          const index = list.indexOf(choice);
          if (index === list.length - 1) break;
          if (index === displays.length) {
            const typed = await askText(question);
            if (typed === undefined) return cancelResult();
            if (typed) toggle(picked, typed);
            continue;
          }
          toggle(picked, options[index].label);
        }
        answers.push({
          question,
          answer: picked.length > 0 ? picked.join(", ") : "(nothing selected)",
        });
      }

      return result(formatAnswers(answers), answers);
    },
  });
}
