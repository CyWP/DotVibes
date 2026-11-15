// The shown space's tabs as a 2px hairline over the panes, in the border
// colour so it meshes with the border lines around it; the shown tab's
// segment is solid accent. A segment click selects its tab; presses pass
// through, so the bar also drags the window (the layout draws no title
// bar) and a double-click on it maximizes.
import { View, div } from "gpui-kit";
import { h_flex } from "gpui-base";
import { spaces, run, theme } from "herdr";

export default class TuiTabs extends View {
  render() {
    const t = theme();
    const shown = spaces().find((s) => s.active)?.tabs ?? [];
    if (!shown.length) return div();
    return h_flex().id("ct-bar").size_full()
      .children(shown.map((c) =>
        div().id(`ct-${c.id}`).flex_1().min_w(0).h_full().bg(c.active ? t.accent : t.border)
          .when(!c.active, (el) => el.hover((st) => st.bg(t.muted)))
          .on_click(() => run("tab.select", { id: c.id }))));
  }
}
