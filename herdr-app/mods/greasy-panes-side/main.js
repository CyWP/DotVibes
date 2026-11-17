// Spike: the old herdr's sidebar, drawn as two copies (props.part "spaces"
// or "agents") so the layout's divider between them can be dragged. Spaces
// grouped by machine, each with its branch, and the shown one with its tabs
// on a strip under it; agents needing you first. The agents copy also draws
// what the old herdr's top line showed: the focused agent's model and
// context, the account's 5-hour and weekly use, the machine and the time.
import { View, div, svg } from "gpui-kit";
import { h_flex, v_flex } from "gpui-base";
import { spaces, agents, machines, panes, run, theme, home, props, setAgentOrder, openOverlay, hc, nextCommand, exec, focused, notify, setShared, shared } from "herdr";

// greasy-panes's rename dialog (greasy-panes-prompt, which draws its own rounded box)
// instead of Herdr's, whose square background pokes out of the app's frame.
function rename(kind, id) {
  const sp = spaces();
  const target = kind === "space" ? sp.find((s) => s.id === id) : sp.flatMap((s) => s.tabs).find((x) => x.id === id);
  openOverlay({
    mod: "greasy-panes-prompt", kind: "dialog", frame: "none", width: 400, height: 214,
    props: {
      title: `rename ${kind}`,
      value: target?.named ? target.name : "",
      hint: kind === "space" ? "empty: named after its folder" : "empty: its number again",
      command: { name: `${kind}.rename`, args: { id } },
    },
  });
}

// The old herdr's popup keys (config.toml [[keys.command]] type "popup"):
// the program in a floating terminal over the tab, gone when it exits.
// Sizes are shares of the window, as there.
const POPUPS = { lazygit: 0.8, btop: 0.9, yazi: 0.9 };

// Theme colours may already carry an alpha (#rrggbbaa — e.g. Herdr's default
// theme's hover); only shade the plain ones, never a colour twice.
const shade = (c, a) => (c && c.length > 7 ? c : c + a);

// What Claude Code reports about each session (model, context, the account's
// 5-hour and weekly limits), saved by extras/claude-usage-hook.sh (in this layout's repo), its
// statusLine command. Newest first: "<mtime>\t<json>" per line.
const USAGE = 'd="$HOME/.local/state/greasy-panes/claude"; for f in $(ls -t "$d"/*.json 2>/dev/null | head -40); do printf "%s\\t" "$(stat -f %m "$f")"; tr -d "\\n" < "$f"; echo; done';

const RANK = { blocked: 0, done: 1, working: 2, idle: 3 };

function short(path) {
  const h = home();
  return !path ? "" : path === h ? "~" : path.startsWith(h + "/") ? "~" + path.slice(h.length) : path;
}

export default class TuiSide extends View {
  init(_props, cx) {
    // Drag to reorder, as the shipped sidebar does: press on a space, release
    // on another of the same machine. Indexes are positions in spaces().
    this.pressed = null;
    this.over = null;
    this.width = 280;
    // Machines folded shut, by name ("" for this Mac); kept across restarts.
    try { this.shut = new Set(JSON.parse(localStorage.getItem("shut") ?? "[]")); } catch { this.shut = new Set(); }
    // Agents in "priority" order: needing you first, then done, working, idle.
    // Each machine's connection as herdr-core reports it (connected,
    // unreachable, or on its way back), polled: machines() only knows
    // whether a layout document arrived.
    this.links = {};
    this.order = [];
    // Each space's checkout as git reports it, by space id: { top, common }.
    // A worktree's common dir is its repo's .git, so it nests under the space
    // holding that repo's main checkout, whatever either folder is called.
    this.git = {};
    // What the old top line carried, drawn by the agents copy: the Claude
    // usage reports. The spaces copy skips that poll.
    this.usage = [];
    if ((props()?.part ?? "spaces") === "agents") this.statusTasks(cx);
    this.tasks(cx);
  }

  // The agents copy's status chore: the Claude usage reports.
  statusTasks(cx) {
    const read = (cx) => exec("sh", ["-c", USAGE]).then((r) => {
      const rows = [];
      for (const line of r.stdout.split("\n")) {
        const tab = line.indexOf("\t");
        if (tab < 0) continue;
        try { rows.push({ at: Number(line.slice(0, tab)) * 1000, ...JSON.parse(line.slice(tab + 1)) }); } catch {}
      }
      this.usage = rows;
      cx.notify();
    }).catch(() => {});
    read(cx);
    cx.timer.every(15000, read);
  }

  // Where a space is now: its first terminal's live folder, else where it was
  // made (a space's folder can be stale, and its name can be anything).
  place(s) {
    const tabs = new Set(s.tabs.map((x) => x.id));
    return panes().find((p) => tabs.has(p.tab) && p.cwd)?.cwd || s.folder;
  }

  // Asks git about every space, one at a time, skipping unreachable machines.
  async probe(cx) {
    let changed = false;
    for (const s of spaces()) {
      if (s.machine && this.links[s.machine] === "unreachable") continue;
      const where = this.place(s);
      if (!where) continue;
      const opts = { cwd: where, on: s.machine };
      const top = await exec("git", ["rev-parse", "--show-toplevel"], opts).catch(() => null);
      const common = await exec("git", ["rev-parse", "--path-format=absolute", "--git-common-dir"], opts).catch(() => null);
      const st = top?.code === 0 ? await exec("git", ["status", "--porcelain"], opts).catch(() => null) : null;
      const dirty = st?.code === 0 && st.stdout.trim() !== "";
      const next = top?.code === 0 && common?.code === 0 ? { top: top.stdout.trim(), common: common.stdout.trim(), dirty } : null;
      if (JSON.stringify(next) !== JSON.stringify(this.git[s.id] ?? null)) { this.git[s.id] = next; changed = true; }
    }
    // The space picker nests worktrees from this map (it runs no git itself).
    if (changed) { setShared("side.git", this.git); cx.notify(); }
  }

  tasks(cx) {
    const poll = (cx) => hc(["machine", "ls", "--json"]).then((r) => {
      const next = {};
      try { for (const m of JSON.parse(r.stdout).machines ?? []) next[m.name] = m.state; } catch {}
      if (JSON.stringify(next) !== JSON.stringify(this.links)) { this.links = next; cx.notify(); }
    }).catch(() => {});
    poll(cx);
    cx.timer.every(10000, poll);
    if ((props()?.part ?? "spaces") === "spaces") {
      cx.spawn(async (cx) => {
        for (;;) {
          await this.probe(cx);
          await new Promise((done) => cx.timer.after(15000, done));
        }
      });
    }
    // Keys bound to greasy-panes-side.<command> (keys.json, layout:greasy-panes).
    cx.spawn(async (cx) => {
      for (;;) {
        const c = await nextCommand();
        const n = Number(/^agent-(\d)$/.exec(c)?.[1]);
        if (n && (props()?.part ?? "spaces") === "agents") {
          const a = this.order[n - 1];
          if (a) { run("space.select", { id: a.space }); run("pane.focus", { pane: a.pane }); }
        }
        if (c === "rename-space" && (props()?.part ?? "spaces") === "spaces") {
          const sp = spaces().find((x) => x.active);
          if (sp) rename("space", sp.id);
        }
        if (c === "fold-toggle" && (props()?.part ?? "spaces") === "spaces") {
          // ctrl-b shift-b: fold the sidebar to its strip, or bring it back.
          if ((this.width ?? 280) <= 48) this.unfold(); else this.fold();
        }
        if ((c === "split-left" || c === "split-up") && (props()?.part ?? "spaces") === "spaces") {
          // pane.split only makes right/down, so split that way and swap the
          // old pane with its new neighbour: the new pane ends up left / above.
          // The swap needs the new pane on screen, so give the split a moment.
          const from = panes().find((x) => x.focused)?.pane;
          if (from) {
            const dir = c === "split-left" ? "right" : "down";
            const ids = new Set(panes().map((x) => x.pane));
            run("pane.split", { direction: dir, pane: from });
            // Trading the old pane with the new one pushes the new pane to
            // the other side (right→left, down→up). Poll for the new pane —
            // usually the next frame, at most ~400ms — then swap the exact
            // pair by id.
            let made = null;
            for (let i = 0; i < 40 && !made; i++) {
              await cx.sleep(10);
              made = panes().map((x) => x.pane).find((x) => !ids.has(x));
            }
            if (made) run("pane.swap", { pane: from, target: made });
          }
        }
        if ((c === "space-next" || c === "space-prev") && (props()?.part ?? "spaces") === "spaces") {
          // alt-j / alt-k and ctrl-b up / down: walk the sidebar's display
          // order (worktrees right after their repo), wrapping at the ends.
          const step = c === "space-next" ? 1 : -1;
          const ids = this.displayOrder ?? [];
          const list = spaces();
          const n = ids.length;
          if (n) {
            let i = ids.indexOf(list.find((x) => x.active)?.id);
            if (i === -1) i = 0;
            for (let k = 1; k <= n; k++) {
              const id = ids[(i + step * k + n * 4) % n];
              if (list.some((x) => x.id === id)) { run("space.select", { id }); break; }
            }
          }
        }
        if ((c === "recent-back" || c === "recent-forward") && (props()?.part ?? "spaces") === "spaces") {
          // ctrl-b left / right: walk back and forward through the spaces
          // you've been on. The walk wraps at the ends (past the oldest
          // lands on the newest and vice versa) but never lands on the
          // space already shown — that would be a dead press. Closed
          // spaces on the way are skipped.
          const step = c === "recent-back" ? -1 : 1;
          const n = (this.hist ?? []).length;
          if (n) {
            let pos = (((this.pos ?? 0) + step) % n + n) % n;
            for (let i = 0; i < n; i++) {
              if (this.hist[pos] !== this.shownSpace && spaces().some((x) => x.id === this.hist[pos])) {
                this.pos = pos;
                this.moving = true;
                run("space.select", { id: this.hist[pos] });
                break;
              }
              pos = ((pos + step) % n + n) % n;
            }
          }
        }
        if (c === "new-worktree" && (props()?.part ?? "spaces") === "spaces") {
          const s = spaces().find((x) => x.active);
          if (s) openOverlay({ mod: "greasy-panes-worktree", kind: "dialog", frame: "none", width: 440, height: 600, props: { space: s.id, action: "new" } });
        }
        // The old bar's keys, here now (keys.json points at this mod): the
        // picker, help, rename-tab and the popup programs, all on the agents
        // copy so the two copies of this mod don't both open one.
        if ((props()?.part ?? "spaces") === "agents") {
          if (c === "picker") openOverlay({ mod: "greasy-panes-picker", kind: "dialog", frame: "none", width: 640, height: 0.45, props: { mode: "spaces" } });
          if (c === "help") openOverlay({ mod: "greasy-panes-help", kind: "dialog", frame: "none", width: 560, height: 560 });
          if (c === "rename-tab") {
            const tab = spaces().find((x) => x.active)?.tabs.find((x) => x.active);
            if (tab) rename("tab", tab.id);
          }
          const name = /^popup-(\w+)$/.exec(c)?.[1];
          if (POPUPS[name]) await this.popup(name, POPUPS[name]);
        }
        cx.notify();
      }
    });
  }

  // The focused agent's model and context (the newest report from its
  // folder), then the account's 5-hour and weekly limits (the newest report
  // of all), resets on hover. Colours as the old plugin's: green, yellow
  // past half, red past 80% used.
  usageLine(t) {
    if (!this.usage.length) return div();
    const cwd = focused()?.cwd;
    const mine = this.usage.find((u) => u.cwd === cwd || u.workspace?.current_dir === cwd);
    const limits = this.usage.find((u) => u.rate_limits);
    const hue = (n) => (n >= 80 ? t.blocked : n >= 50 ? t.working : t.done);
    const reset = (sec) => {
      const d = new Date(sec * 1000), now = new Date();
      const hm = `${d.getHours() % 12 || 12}:${String(d.getMinutes()).padStart(2, "0")}${d.getHours() < 12 ? "am" : "pm"}`;
      return d.toDateString() === now.toDateString() ? hm : `${["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][d.getDay()]} ${hm}`;
    };
    const item = (id, label, n, tip) => h_flex().id(id).gap(5).items_center()
      .when(Boolean(tip), (el) => el.tooltip(tip))
      .child(div().text_color(t.dim).child(label))
      .child(div().font_bold().text_color(hue(n)).child(`${Math.round(n)}%`));
    const ctx = mine?.context_window?.used_percentage;
    const five = limits?.rate_limits?.five_hour, week = limits?.rate_limits?.seven_day;
    return h_flex().gap(14).items_center().text_size(12.5)
      .when(Boolean(mine?.model?.display_name), (el) => el.child(div().text_color(t.muted).child(mine.model.display_name)))
      .when(ctx != null, (el) => el.child(item("cu-ctx", "ctx", ctx, null)))
      .when(five?.used_percentage != null, (el) => el.child(item("cu-5h", "5h", five.used_percentage, five.resets_at ? `resets ${reset(five.resets_at)}` : null)))
      .when(week?.used_percentage != null, (el) => el.child(item("cu-week", "week", week.used_percentage, week.resets_at ? `resets ${reset(week.resets_at)}` : null)));
  }

  // The old bar's popups: the program in a floating terminal over the tab,
  // gone when it exits. Sizes are shares of the window (0.8 = 80%), so they
  // follow the window's shape without assuming 16:9.
  async popup(program, share) {
    const cwd = focused()?.cwd;
    const r = await hc(["run", "--bg", "--json", "--no-parent", "--rm", ...(cwd ? ["--cwd", cwd] : []), "--", program]).catch(() => null);
    let address = null;
    try { address = r?.code === 0 ? JSON.parse(r.stdout).address : null; } catch {}
    if (!address) { notify({ title: `Couldn't start ${program}`, body: r?.stderr?.trim() || "Is it installed?", level: "error" }); return; }
    openOverlay({ kind: "dialog", key: `greasy-panes-popup-${program}`, width: share, height: share, layout: { type: "block", content: { terminal: address } } });
  }

  menu(s) {
    openOverlay({ mod: "greasy-panes-menu", kind: "popup", frame: "none", width: 280, height: 260, props: { tab: "space", target: { id: s.id } } });
  }

  toggle(key, cx) {
    if (this.shut.has(key)) this.shut.delete(key); else this.shut.add(key);
    try { localStorage.setItem("shut", JSON.stringify([...this.shut])); } catch {}
    cx.notify();
  }

  // « folds the sidebar to a strip, » brings it back at its last width.
  fold() {
    try { localStorage.setItem("width", String(Math.round(this.width))); } catch {}
    run("layout.resize", { id: "sidebar", px: 40 });
  }

  unfold() {
    let px = 280;
    try { px = Number(localStorage.getItem("width")) || 280; } catch {}
    run("layout.resize", { id: "sidebar", px: Math.max(px, 160) });
  }

  render() {
    const t = theme();
    const list = spaces();
    // Recent spaces for ctrl-b left / right: a back/forward list with a
    // position. Each time the shown space changes on its own (not through
    // recent-back / recent-forward, which set this.moving), the forward
    // entries are dropped and the space is pushed.
    const shown = list.find((x) => x.active)?.id;
    if (shown && shown !== this.shownSpace) {
      if (!this.moving) {
        this.hist = (this.hist ?? []).slice(0, (this.pos ?? -1) + 1);
        if (this.hist[this.hist.length - 1] !== shown) this.hist.push(shown);
        this.pos = this.hist.length - 1;
      }
      this.moving = false;
      this.shownSpace = shown;
    }
    // The display order for space-next / space-prev: each top space followed
    // by its worktrees, per machine — the order the sidebar draws, not the
    // raw spaces() order (worktrees created later would otherwise be
    // walked last).
    this.displayOrder = [];
    const ags = [...agents()].sort((a, b) => (RANK[a.status] ?? 9) - (RANK[b.status] ?? 9) || b.seq - a.seq);
    this.order = ags;
    setAgentOrder(ags.map((a) => a.address));
    const tint = (st) => (st ? t[st] ?? t.dim : t.border);
    const dot = (st, size = 8) => div().flex_none().size(size).rounded(size / 2).bg(tint(st));

    // One row per space: a lifted background marks the shown one. A repo with
    // worktrees under it gets ▾ / ▸ at the right end to fold them.
    const space = (s) => {
      const i = list.indexOf(s);
      return h_flex().id(`cs-${s.id}`).relative().px(10).py(4).gap(8).rounded(4).items_center()
      .when(s.active, (el) => el.bg(shade(t.selected, "b3")))
      .when(!s.active, (el) => el.hover((st) => st.bg(shade(t.border, "b3"))))
      .when(this.pressed === i && this.over !== i, (el) => el.opacity(0.5))
      .when(this.pressed !== null && this.over === i && this.pressed !== i, (el) => el.child(
        div().absolute().left(0).right(0).h(2).bg(t.accent)
          .when(this.pressed < i, (line) => line.bottom(0))
          .when(this.pressed > i, (line) => line.top(0))))
      .on_mouse_down("left", (_e, cx) => { cx.stop_propagation(); this.pressed = i; this.over = i; })
      .on_mouse_down("right", (_e, cx) => { cx.stop_propagation(); this.menu(s); })
      .on_mouse_move((_e, cx) => {
        const source = list[this.pressed];
        const over = source && (source.machine ?? null) === (s.machine ?? null) ? i : null;
        if (this.pressed !== null && this.over !== over) { this.over = over; cx.notify(); }
      })
      .on_mouse_up("left", (_e, cx) => {
        const from = this.pressed, over = this.over;
        this.pressed = null; this.over = null;
        if (from !== null && over === i && from !== i) run("space.move", { id: list[from].id, index: i + 1 });
        else if (from === i) run("space.select", { id: s.id });
        cx.notify();
      })
      // One line: the name (status-coloured), then its folder when that
      // isn't the name. The branch lives in its own panel below.
      .child(h_flex().flex_1().min_w(0).gap(8).items_center().text_size(12.5)
        .child(div().flex_shrink(0).max_w(150).truncate().text_color(s.status ? tint(s.status) : s.active ? t.foreground : t.muted).when(s.active, (el) => el.font_bold()).child(s.name))
        .child(div().flex_1().min_w(0).truncate().text_color(t.dim)
          .child((short(s.folder) || "~") !== s.name ? short(s.folder) : "")))
      .when(Boolean(s.status) && s.status !== "idle", (el) => el.child(dot(s.status)))

    };

    // Worktrees, as the old herdr drew them: under their repo's space, one
    // line each on a ├─ / └─ tree. Git decides (see probe): a space is a
    // worktree when its repo's .git isn't in its own checkout, and it goes
    // under the space (same machine) whose checkout is that repo's main one.
    const linked = (s) => { const g = this.git[s.id]; return Boolean(g) && g.common !== `${g.top}/.git`; };
    // The tree is drawn, not typed: ├─ glyphs leave gaps between rows that
    // aren't a terminal's exact cell height. A trunk runs down the left (to
    // the middle on the last row, so it ends in └) and a twig goes right.
    // The trunk reaches 2px up into the row above to bridge the list's gap.
    const branchRow = (s, last) => h_flex().id(`cs-${s.id}`).relative().h(20).pl(30).pr(10).gap(6).rounded(4).items_center().text_size(12.5)
      .when(s.active, (el) => el.bg(shade(t.selected, "b3")))
      .when(!s.active, (el) => el.hover((st) => st.bg(shade(t.border, "b3"))))
      .on_click(() => run("space.select", { id: s.id }))
      // The sidebar block drags the window; rows opt their presses out.
      .on_mouse_down("left", (_e, cx) => cx.stop_propagation())
      .on_mouse_down("right", (_e, cx) => { cx.stop_propagation(); this.menu(s); })
      // The elbow: a rounded quarter-turn into the row. Worktrees with a
      // next sibling keep the trunk running through below the curve.
      .child(div().absolute().left(14).top(last ? -2 : 4).w(10).h(last ? 12 : 6).border_l(1).border_b(1).rounded_bl(6).border_color(t.border))
      .when(!last, (el) => el.child(div().absolute().left(14).top(-2).w(1).h(22).bg(t.border)))
      .child(div().flex_1().min_w(0).truncate().text_color(s.status ? tint(s.status) : s.active ? t.foreground : t.muted).when(s.active, (el) => el.font_bold())
        .child(s.branch ?? s.name));
    const tree = (own) => {
      const tops = own.filter((s) => !linked(s));
      const common = (s) => this.git[s.id]?.common;
      // The repo's main checkout first; any other space in the same repo after.
      const parent = (w) => tops.find((p) => common(p) === common(w) && this.git[p.id].top + "/.git" === common(w))
        ?? tops.find((p) => common(p) === common(w));
      const rows = [];
      for (const s of own) {
        if (linked(s) && parent(s)) continue; // drawn under its repo
        const kids = linked(s) ? [] : own.filter((w) => linked(w) && parent(w) === s);
        rows.push(space(s));
        this.displayOrder.push(s.id);
        kids.forEach((w, i) => { rows.push(branchRow(w, i === kids.length - 1)); this.displayOrder.push(w.id); });
      }
      return rows;
    };

    // One panel per machine, in machines() order: its spaces inside, its
    // name and link dot as the card's bottom label; the label toggles the
    // panel. Open panels share the block's height, folded ones slink.
    const machine = (m, i) => {
      const own = list.filter((s) => (s.machine ?? null) === m.name);
      const link = m.name == null ? "connected" : this.links[m.name] ?? (m.layout === "unavailable" ? "unreachable" : "connected");
      const down = link === "unreachable";
      const back = !down && link !== "connected"; // on its way back: reconnecting
      const key = m.name ?? "";
      const shut = this.shut.has(key);
      // Shut, the label still shows the most urgent agent status inside it.
      const worst = own.map((s) => s.status).filter(Boolean).sort((a, b) => (RANK[a] ?? 9) - (RANK[b] ?? 9))[0];
      const el = shut ? v_flex().flex_none() : v_flex().flex_1().min_h(0);
      const cardEl = el.text_color(t.foreground)
        .mt(i === 0 ? 4 : 3).mb(i === ms.length - 1 ? 0 : 3).mx(3)
        .rounded(6).border_1().border_color(t.border).bg(shade(t.background, "c7"));
      if (!shut) cardEl.child(v_flex().flex_1().min_h(0).overflow_y_scroll()
        // A release outside any space cancels the drag.
        .on_mouse_up("left", (_e, cx) => { if (this.pressed !== null) { this.pressed = null; this.over = null; cx.notify(); } })
        .children(tree(own)));
      cardEl.child(h_flex().flex_none().px(10).pb(4).pt(1).gap(6).items_center()
        .on_click((_e, cx) => this.toggle(key, cx))
        .child(div().text_size(12.5).text_color(t.muted).child((m.name ?? "local").toLowerCase()))
        .when(shut && Boolean(worst) && worst !== "idle", (el2) => el2.child(dot(worst)))
        .child(dot(down ? "blocked" : back ? "working" : "done", 4)));
      return cardEl;
    };

    // As the old herdr's agents list: a ring or dot, the space · its tab, and
    // under it what the agent is doing. Every agent here is Claude Code, so
    // the program isn't repeated on each row.
    // The terminal title leads with the program's short name ("OC | …");
    // the row shows just the description after it.
    const desc = (a) => (a.title || "").replace(/^[^|]{1,16}\|\s*/, "") || a.title || "—";
    const agent = (a) => h_flex().id(`ca-${a.address}`).px(10).py(4).gap(7).items_start().rounded(4)
      .when(a.focused, (el) => el.bg(shade(t.selected, "b3")))
      .when(a.status === "blocked", (el) => el.bg(shade(t.blocked, "1f")))
      .when(!a.focused, (el) => el.hover((st) => st.bg(shade(t.hover, "b3"))))
      .on_mouse_down("left", (_e, cx) => cx.stop_propagation())
      .on_click(() => { run("space.select", { id: a.space }); run("pane.focus", { pane: a.pane }); })
      .child(v_flex().flex_1().min_w(0)
        .child(h_flex().gap(6).text_size(12.5)
          .child(div().flex_shrink(1).min_w(0).truncate().text_color(a.status ? tint(a.status) : t.foreground).when(a.focused, (el) => el.font_bold()).child(a.space_name)))
        .child(div().truncate().text_size(12.5).text_color(t.muted).child(desc(a))));

    const waiting = ags.filter((a) => a.status === "blocked").length;
    const part = props()?.part ?? "spaces";
    const sized = (el) => el.id(`cs-root-${part}`).on_size_change((size, cx) => {
      if (Math.abs(size.width - this.width) >= 1) { this.width = size.width; cx.notify(); }
    });
    // The card is drawn by the mod, not the layout, so the margins can
    // differ per side: 4 at the top, 4 at the bottom, 3 at the sides; the
    // 5px between the cards comes from the column gap.
    // Like the pane frames, the card paints NO fill — the panels inside
    // carry the terminal-surface wash themselves.
    const card = (el) => el.flex_1().min_h(0).text_color(t.foreground)
      .mt(part === "spaces" ? 4 : 0).mb(part === "spaces" ? 0 : 3).mx(3)
      .rounded(6).border_1().border_color(t.border)
      // the same base as the terminals: their surface paints ~78% over the
      // wallpaper (terminal_opacity 0.68, measured), so the cards match
      .bg(shade(t.background, "c7"));
    const chevron = (id, label, action) => div().id(id).px(6).rounded(4).text_size(12.5).text_color(t.dim)
      .on_mouse_down("left", (_e, cx) => cx.stop_propagation())
      .hover((st) => st.bg(shade(t.hover, "b3")).text_color(t.foreground)).on_click(action).child(label);
    // The window controls the system doesn't draw on Linux (close, minimize,
    // maximize-toggle) and the app's settings, as lucide icons tinted with
    // the text colour; closing tints red under the pointer. Assets come
    // from Herdr's shipped workspace-chrome mod.
    const winBtn = (id, icon, action, th) => div().id(id).px(5).py(4).rounded(4).text_color(th.dim)
      .on_mouse_down("left", (_e, cx) => cx.stop_propagation())
      .hover((st) => action === "window.close"
        ? st.bg(shade(th.blocked, "b3")).text_color(th.blocked)
        : st.bg(shade(th.hover, "b3")).text_color(th.foreground))
      .on_click(() => typeof action === "function" ? action() : run(action))
      .child(svg(`mods/${icon}.svg`).size(13));

    // The halves' names at the bottom of each card, in the agent
    // description's lettering (12.5, muted); the agents one carries the
    // needs-attention count when there is any.
    const label = (text, waiting) => h_flex().flex_none().px(10).pb(4).pt(1).gap(6).items_baseline()
      .child(div().text_size(12.5).text_color(t.muted).child(text))
      .when(Boolean(waiting), (el) => el.child(div().text_size(12.5).text_color(t.blocked).child(`${waiting} need you`)));
    // Folded, as the old herdr's rail: each space by its number on its
    // machine (other machines open with ▾ and their position), then each
    // agent by its space's first letter; a status mark after each. All
    // three panels stay in both states: the rail cards lose their labels
    // and the bottom panel stacks its buttons, with » to unfold.
    const folded = this.width < 60;
    const ms = machines();
    let root;
    if (folded) {
      const cell = (id, label, st, on, action) => h_flex().id(id).w_full().h(19).px(4).gap(1).justify_center().items_center()
        .rounded(3).text_size(12.5).bg(on ? shade(t.selected, "b3") : shade(t.background, "4d"))
        .when(!on, (el) => el.hover((s) => s.bg(shade(t.hover, "b3")))).on_mouse_down("left", (_e, cx) => cx.stop_propagation()).on_click(action)
        .child(div().text_color(st ? tint(st) : on ? t.accent : t.muted).when(on, (el) => el.font_bold()).child(label));
      if (part === "spaces") {
        const rail = machines().flatMap((m, mi) => {
          const own = list.filter((s) => (s.machine ?? null) === m.name);
          const head = mi === 0 ? [] : [h_flex().w_full().h(19).justify_center().items_center().text_size(12.5)
            .text_color(m.layout === "unavailable" ? t.blocked : t.accent).child(`▾${mi + 1}`)];
          return [...head, ...own.map((s, i) => cell(`cr-${s.id}`, String(i + 1), s.status, s.active, () => run("space.select", { id: s.id })))];
        });
        root = sized(v_flex().size_full())
          .child(card(v_flex().px(3).pt(4))
            .child(v_flex().id("cr-spaces").flex_1().min_h(0).overflow_y_scroll().children(rail)));
      } else {
        root = sized(v_flex().size_full())
          .child(card(v_flex().px(3).pt(6))
            .child(v_flex().id("cr-agents").flex_1().min_h(0).overflow_y_scroll()
              .children(ags.map((a) => cell(`cra-${a.address}`, [...(a.space_name || "?")][0] ?? "?", a.status, a.focused,
                () => { run("space.select", { id: a.space }); run("pane.focus", { pane: a.pane }); })))));
      }
    } else if (part === "spaces") {
      root = sized(v_flex().size_full())
        .children(ms.map((m, i) => machine(m, i)));
    } else {
      root = sized(v_flex().size_full())
        .child(card(v_flex().flex_1().min_h(0))
          .child(v_flex().id("cs-agents").flex_1().min_h(0).overflow_y_scroll()
            .when(ags.length === 0, (el) => el.child(div().px(10).py(6).text_size(12.5).text_color(t.dim)
              .child("No agents here yet. Start one from the picker (ctrl-b w) or ctrl-b c.")))
            .children(ags.map(agent)))
          .child(label("agents", waiting)));
    }
    // The shown space's git branch, in its own small panel between the
    // agents card and the bottom one (expanded only; the rail is too narrow).
    const shownSpace = list.find((s) => s.active);
    // The spaces copy runs the git probe and shares it; read it here.
    const gitMap = props()?.part === "spaces" ? this.git : shared("side.git") ?? {};
    const info = shownSpace ? gitMap[shownSpace.id] : null;
    const inRepo = Boolean(info);
    const hasBranch = Boolean(shownSpace?.branch);
    const dirty = Boolean(info?.dirty);
    const branchPanel = v_flex().flex_none().mt(3).mx(3).mb(3).rounded(6).border_1().border_color(t.border).bg(shade(t.background, "c7"))
      .px(10).py(5)
      .child(h_flex().items_center().justify_between()
        .child(div().min_w(0).truncate().text_size(12.5).text_color(t.muted)
          .child(hasBranch ? shownSpace.branch : inRepo ? "detached" : "no repo"))
        .child(svg("mods/workspace-chrome/git-branch.svg").size(13).text_color(!inRepo || !hasBranch ? t.muted : dirty ? t.working : t.accent)));
    // The bottom panel in both states: the usage numbers, the window
    // controls the system doesn't draw on Linux and the app's settings —
    // spread across the width expanded, stacked in the rail, where the
    // chevron turns » and unfolds.
    const panel = v_flex().flex_none().mt(3).mx(3).mb(5).rounded(6).border_1().border_color(t.border).bg(shade(t.background, "c7"));
    const btns = [
      ["cs-win-close", "workspace-chrome/x", "window.close"],
      ["cs-win-min", "workspace-chrome/minus", "window.minimize"],
      ["cs-win-max", "workspace-chrome/square", "window.maximize"],
      ["cs-settings", "workspace-chrome/settings", "app.settings"],
      ["cs-help", "greasy-panes-side/question-mark",
        () => openOverlay({ mod: "greasy-panes-help", kind: "dialog", frame: "none", width: 560, height: 560 })],
      ["cs-search", "workspace-chrome/search", "app.palette"],
    ];
    if (folded) {
      panel.px(2).py(4).gap(2).items_center();
      panel.child(chevron("cs-unfold", "»", () => this.unfold()));
      for (const [id, icon, cmd] of [...btns].reverse()) panel.child(winBtn(id, icon, cmd, t));
    } else {
      panel.px(10).py(5).gap(3);
      panel.when(Boolean(this.usage.length), (el) => el.child(this.usageLine(t)));
      panel.child(h_flex().items_center().justify_between()
        .children([...btns.map(([id, icon, cmd]) => winBtn(id, icon, cmd, t)), chevron("cs-fold", "«", () => this.fold())]));
    }
    // The bottom panel lives in the agents copy only; the spaces copy is
    // its card alone, in both states.
    if (part === "spaces") return root;
    if (!folded) root = root
      .when(Boolean(shownSpace), (el) => el.child(branchPanel));
    return root.child(panel);
  }
}
