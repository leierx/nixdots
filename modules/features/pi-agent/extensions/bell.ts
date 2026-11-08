import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

// tmux marks the window when it is not the one on screen
function bell(ctx: ExtensionContext): void {
	if (ctx.mode === "tui") process.stdout.write("\x07");
}

export default function (pi: ExtensionAPI) {
	pi.on("agent_settled", (event, ctx) => {
		if (!event.aborted) bell(ctx);
	});
	pi.on("ui_prompt_start", (_event, ctx) => bell(ctx));
}
