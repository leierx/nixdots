import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// tmux-resurrect's save hook restores the pane with `pi --session` on this file
export default function (pi: ExtensionAPI) {
	pi.on("session_start", async (_event, ctx) => {
		const pane = process.env.TMUX_PANE;
		if (!pane) return;
		const file = ctx.sessionManager.getSessionFile();
		const result = await pi.exec(
			"@tmux@",
			file
				? ["set-option", "-p", "-t", pane, "@pi_session", file]
				: ["set-option", "-p", "-u", "-t", pane, "@pi_session"],
		);
		if (result.code !== 0) ctx.ui.notify(`tmux-session: ${result.stderr.trim()}`, "error");
	});
}
