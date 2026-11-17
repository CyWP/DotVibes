// The shown space's tabs as a 1px hairline under the panes, in the border
// colour (the cards' edges); the shown tab's segment carries a 4px pill
// with rounded ends over it, in the muted colour (the terminal scrollbar
// thumb's colour and thickness). A segment click selects its tab; presses
// pass through, so the bar also drags the window (the layout draws no
// title bar) and a double-click on it maximizes.
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
        div().id(`ct-${c.id}`).flex_1().min_w(0).h_full().relative()
          // the hairline this segment contributes to the bar's line; it sits
          // on the window's bottom edge side of the block. In the shown tab
          // it runs in the muted behind the pill, so the pill's rounded
          // corners read filled.
          .child(
            div().absolute().left(0).right(0).top(2).h(1)
              .bg(c.active ? t.muted : t.border)
              .when(!c.active, (el) => el.hover((st) => st.bg(t.muted))),
          )
          .when(c.active, (el) =>
            el.child(div().absolute().left(0).right(0).top(0).h(4).rounded(2).bg(t.muted)))
          .on_click(() => run("tab.select", { id: c.id }))));
  }
}
