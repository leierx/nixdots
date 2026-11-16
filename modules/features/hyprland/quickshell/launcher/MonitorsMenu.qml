import Quickshell
import qs.common
import "search.js" as Search

MenuWindow {
  id: root

  property var rows: []

  fullHeight: list.fullHeight

  MenuCommand {
    id: status

    command: ["hyprmoncfg", "status", "--json"]
    onDone: output => {
      let parsed;
      try {
        parsed = JSON.parse(output);
      } catch (error) {
        status.fail(String(error));
        return;
      }
      const profiles = (parsed.profiles ?? [])
        .map(profile => ({
          key: profile.name,
          title: profile.name,
          subtitle: profile.active ? "Active" : "",
          profile: profile.name,
        }))
        .sort((a, b) => a.title.localeCompare(b.title));
      const recommended = parsed.recommended_profile?.name;
      // The daemon keeps a hand-picked profile until the next hotplug; "Auto" applies what it would pick.
      root.rows = recommended
        ? [{ key: "", title: "Auto", subtitle: recommended, profile: recommended }, ...profiles]
        : profiles;
    }
  }

  MenuList {
    id: list

    placeholder: "Monitor layout…"
    results: root.rows.filter(row => Search.scoreFields(list.query, [[1.0, row.title], [0.8, row.subtitle]]) >= 0)
    onActivated: row => {
      // The menu is gone by then, so a failure comes back as a notification.
      Quickshell.execDetached(["sh", "-c", 'out=$(hyprmoncfg apply --confirm-timeout 0 "$1" 2>&1) || notify-send -u critical "hyprmoncfg: $1" "$out"', "sh", row.profile]);
      Panels.close();
    }
  }
}
