import Quickshell
import qs.common
import qs.nix
import "search.js" as Search

// hyprmoncfg's profiles, led by the one it recommends for the connected outputs.
MenuWindow {
  id: root

  property var rows: []

  fullHeight: list.fullHeight

  MenuCommand {
    command: [Bin.hyprmoncfg, "status", "--json"]
    onDone: output => {
      const status = JSON.parse(output);
      const profiles = (status.profiles ?? [])
        .map(profile => ({
          title: profile.name,
          subtitle: profile.active ? "Active" : "",
          profile: profile.name,
        }))
        .sort((a, b) => a.title.localeCompare(b.title));
      const recommended = status.recommended_profile?.name;
      // the daemon keeps a hand-picked profile until the next hotplug; this applies what it would pick
      root.rows = recommended
        ? [{ title: "Auto", subtitle: recommended, profile: recommended }, ...profiles]
        : profiles;
    }
  }

  MenuList {
    id: list

    placeholder: "Monitor layout…"
    results: root.rows.filter(row => Search.scoreFields(list.query, [[1.0, row.title], [0.8, row.subtitle]]) >= 0)
    onActivated: row => {
      Quickshell.execDetached([Bin.applyMonitorLayout, row.profile]);
      Panels.close();
    }
  }
}
