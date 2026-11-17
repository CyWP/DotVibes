// Modified from Herdr's shipped `worktree` mod (Apache-2.0).
// Changes: draws its own rounded box (opened with frame: "none"); the new
// worktree dialog gained a base branch (with suggestions, fetch and
// validation) and a startup script picker (scripts.json + custom commands),
// ported from the herdrtw layout's worktree.js (Apache-2.0, see NOTICE);
// tab / shift-tab cycle the dialog's fields and never pick suggestions
// (the base list runs on arrows + enter; the startup script dropdown opens
// and is driven from the keyboard too); the dialog matches the pane cards'
// radius and translucency.
// Worktree dialog: { space, action: "new" | "open" | "remove" } or
// { folder, machine } for a repo without a space; optional { branch, tab, argv, base }.

import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex, InputState, Input, Scrollbar } from "gpui-base";
import { run, props, closeOverlay, theme, spaces, panes, exec, home, appHome, readTextFile, writeTextFile } from "herdr";
// Theme colours may already carry an alpha (#rrggbbaa); only shade the plain ones.
const shade = (c, a) => (c && c.length > 7 ? c : c + a);


// Where a space is now: its first terminal's live folder, else where it was made.
function place(s) {
  if (!s) return null;
  const tabs = new Set((s.tabs ?? []).map((c) => c.id));
  return panes().find((p) => tabs.has(p.tab) && p.cwd)?.cwd || s.folder || null;
}

// Checkouts go to <ROOT>/<repo>/<branch, slashes as dashes>.
const ROOT = (home) => `${home}/.herdr/worktrees`;
// Home as ~ (git says C:/Users/x where Windows says C:\Users\x).
const tilde = (path, userHome) => {
  const [p, h] = [path, userHome].map((s) => s.replace(/\\/g, "/"));
  return p.startsWith(h) ? `~${p.slice(h.length)}` : path;
};
const slug = (branch) => branch.replace(/[^A-Za-z0-9._-]+/g, "-").replace(/^-+|-+$/g, "");
const ago = (s) => {
  const d = Date.now() / 1000 - s;
  return d < 3600 ? `${Math.max(1, Math.round(d / 60))}m` : d < 86400 ? `${Math.round(d / 3600)}h` : d < 86400 * 60 ? `${Math.round(d / 86400)}d` : `${Math.round(d / 86400 / 30)}mo`;
};

// Every checkout of a repo (`git worktree list`), the main one first, then
// the most recently committed: { path, branch, main, at }.
async function checkouts(repo, on) {
  const list = await git(repo.main, ["worktree", "list", "--porcelain"], on);
  if (!list.ok) return [];
  const refs = await git(repo.main, ["for-each-ref", "--format=%(refname:short)%09%(committerdate:unix)", "refs/heads"], on);
  const when = new Map(refs.out.split("\n").map((l) => l.split("\t")).map(([b, at]) => [b, Number(at) || 0]));
  const out = [];
  for (const block of list.out.split(/\n\n+/)) {
    const lines = block.split("\n");
    const path = lines.find((l) => l.startsWith("worktree "))?.slice(9);
    if (!path || lines.some((l) => l === "bare" || l.startsWith("prunable"))) continue;
    const branch = lines.find((l) => l.startsWith("branch "))?.slice(7).replace(/^refs\/heads\//, "") ?? null;
    out.push({ path, branch, main: out.length === 0, at: branch ? (when.get(branch) ?? 0) : 0 });
  }
  return out.sort((a, b) => b.main - a.main || b.at - a.at);
}

// The space showing a checkout: its first terminal is in it (the deepest checkout wins).
function spaceOf(path, all, on) {
  const inside = (p, dir) => p === dir || p.startsWith(dir + "/");
  return spaces().find((s) => (s.machine ?? null) === (on ?? null) && (() => {
    const at = place(s)?.replace(/\\/g, "/");
    if (!at || !inside(at, path)) return false;
    return !all.some((c) => c.path !== path && c.path.length > path.length && inside(at, c.path));
  })());
}

async function git(cwd, args, on, timeout) {
  const r = await exec("git", args, { cwd, on, ...(timeout === undefined ? {} : { timeout }) });
  return { ok: r.code === 0, out: (r.stdout ?? "").trim(), err: (r.stderr ?? r.stdout ?? "").trim() };
}

// The submodule repos git keeps for a checkout (nested ones too, checked out
// or not): { name, dir, pinned }. `config` is the args that read its
// .gitmodules; `pinned` is the commit its parent records ("" if none).
async function modules(gitDir, config, on, out = [], parent = "") {
  const keys = await git(gitDir, ["--git-dir", gitDir, "config", ...config, "-z", "--get-regexp", "^submodule\\..*\\.path$"], on);
  if (!keys.ok) return out; // no .gitmodules, or no submodules in it
  // -z: "key\nvalue" records ended by NUL, so names and paths may hold spaces.
  for (const record of keys.out.split("\0").filter(Boolean)) {
    const at = record.indexOf("\n");
    const name = record.slice("submodule.".length, at - ".path".length);
    const dir = `${gitDir}/modules/${name}`;
    if (!(await git(gitDir, ["--git-dir", dir, "rev-parse", "--git-dir"], on)).ok) continue; // never checked out
    const pinned = await git(gitDir, ["--git-dir", gitDir, "rev-parse", `HEAD:${record.slice(at + 1)}`], on);
    // Names are only unique within their parent: nested ones carry its name.
    out.push({ name: parent + name, dir, pinned: pinned.ok ? pinned.out : "" });
    if ((await git(gitDir, ["--git-dir", dir, "cat-file", "-e", "HEAD:.gitmodules"], on)).ok) await modules(dir, ["--blob", "HEAD:.gitmodules"], on, out, `${parent + name}/`);
  }
  return out;
}

// The worktree's submodules, and the names of those with commits that exist
// nowhere else: not on a remote, and not the commit the parent pins (git
// fetches that by hash, so it is often on no remote branch here).
async function submodules(top, on) {
  const gitDir = await git(top, ["rev-parse", "--absolute-git-dir"], on);
  if (!gitDir.ok) throw new Error(gitDir.err || "git rev-parse failed.");
  const mods = await modules(gitDir.out, ["--file", `${top}/.gitmodules`], on);
  const unpushed = [];
  for (const m of mods) {
    const local = await git(gitDir.out, ["--git-dir", m.dir, "rev-list", "-n1", "--all", "--not", "--remotes", ...(m.pinned ? [m.pinned] : [])], on);
    if (!local.ok) throw new Error(local.err || `Couldn't check submodule ${m.name}.`);
    if (local.out) unpushed.push(m.name);
  }
  return { mods, unpushed };
}

// The repo a folder belongs to: its main checkout and name, and whether
// the folder is itself a linked worktree. null outside git.
async function repoOf(folder, on) {
  const top = await git(folder, ["rev-parse", "--show-toplevel"], on);
  const common = await git(folder, ["rev-parse", "--path-format=absolute", "--git-common-dir"], on);
  if (!top.ok || !common.ok) return null;
  const main = common.out.endsWith("/.git") ? common.out.slice(0, -5) : common.out;
  return { top: top.out, main, name: main.split("/").pop(), linked: main !== top.out };
}

const label = (t, title, hint) => h_flex().gap(6).items_baseline().child(div().text_size(12).font_medium().text_color(t.foreground).child(title)).child(div().text_size(11).text_color(t.dim).child(hint));

export default class Worktree extends View {
  init(_props, cx) {
    this.on = this.space()?.machine;
    this.userHome = this.on ? null : home();
    this.opening = props()?.action === "open";
    this.text = props()?.branch ?? "";
    this.list = undefined; // open: the checkouts, once read
    this.at = 0;
    this.input = InputState.new({ value: this.text, placeholder: this.opening ? "filter worktrees" : "branch name" });
    this.input.on("change", (_e, cx) => { this.text = this.input.value(); this.error = ""; this.at = 0; cx.notify(); });
    this.input.on("submit", (_e, cx) => this.go(cx));
    this.inputFocused = true;
    this.input.on("focus", (_e, cx) => { this.inputFocused = true; this.scriptFocused = false; cx.notify(); });
    this.input.on("blur", (_e, cx) => { this.inputFocused = false; cx.notify(); });
    if (props()?.action !== "remove") {
      this.input.focus();
      cx.timer.after(600, () => this.input.focus());
    }
    // The branch the new one starts from: typed, or picked from a suggestion
    // list of the repo's local and remote branches while the field is focused.
    this.baseText = props()?.base ?? "";
    this.baseInput = InputState.new({ value: this.baseText, placeholder: "base branch" });
    this.baseInput.on("change", (_e, cx) => { this.baseText = this.baseInput.value(); this.error = ""; this.sugAt = 0; this.sugTouched = false; cx.notify(); });
    this.baseInput.on("submit", (_e, cx) => { if (this.sugTouched && this.suggestions().length) return this.pick(this.suggestions()[this.sugAt], cx); this.go(cx); });
    this.branches = [];
    this.sugAt = 0;
    this.sugTouched = false;
    this.baseFocused = false;
    this.baseInput.on("focus", (_e, cx) => { this.baseFocused = true; this.scriptFocused = false; cx.notify(); });
    this.baseInput.on("blur", (_e, cx) => { this.baseFocused = false; cx.notify(); });
    // The command that runs in the new space's first terminal: a script from
    // scripts.json next to this mod, or a custom one typed on the spot.
    this.stepText = "";
    this.scriptsRaw = null;
    this.scriptsLoaded = false;
    this.defaultCommand = undefined;
    this.defaultApplied = false;
    this.custom = "";
    this.customInput = InputState.new({ value: "", placeholder: "command, e.g. npm install && npm run dev" });
    this.customInput.on("change", (_e, cx) => { this.custom = this.customInput.value(); this.error = ""; cx.notify(); });
    this.customInput.on("submit", (_e, cx) => this.go(cx));
    this.customFocused = false;
    this.customInput.on("focus", (_e, cx) => { this.customFocused = true; this.scriptFocused = false; cx.notify(); });
    this.customInput.on("blur", (_e, cx) => { this.customFocused = false; cx.notify(); });
    this.scripts = [{ name: "No script" }, { name: "Custom…", custom: true }];
    this.scriptAt = 0;
    this.scriptOpen = false;
    this.scriptFocused = false;
    cx.spawn(async (cx) => {
      try {
        const raw = await readTextFile(`${appHome()}/mods/greasy-panes-worktree/scripts.json`);
        this.scriptsRaw = raw;
        const list = JSON.parse(raw ?? "[]").filter((x) => x && x.name && x.command);
        this.scripts = [{ name: "No script" }, ...list, { name: "Custom…", custom: true }];
      } catch {}
      this.scriptsLoaded = true;
      this.applyDefaultScript();
      cx.notify();
    });
    this.busy = false;
    this.error = "";
    this.repo = undefined; // undefined: looking, null: not in git
    this.dirty = false;
    this.unpushed = [];
    this.handle = cx.focus_handle();
    if (props()?.action === "remove") this.handle.focus();
    cx.spawn(async (cx) => {
      try {
        if (this.on) {
          let result;
          try { result = await exec("sh", ["-c", 'printf %s "$HOME"'], { on: this.on }); } catch {}
          if (!result || result.code !== 0 || !result.stdout.trim()) result = await exec("powershell.exe", ["-NoProfile", "-Command", "[Console]::Write($HOME)"], { on: this.on });
          if (result.code !== 0 || !result.stdout.trim()) throw new Error("Could not find the remote home folder.");
          this.userHome = result.stdout.trim().replace(/\\/g, "/");
        }
        this.folder = props()?.folder || place(this.space()) || this.userHome;
        // The repo is set last: Enter does nothing until the warnings it consents to are known.
        const repo = await repoOf(this.folder, this.on);
        if (repo && props().action === "remove") {
          this.dirty = (await git(repo.top, ["--no-optional-locks", "-c", "core.fsmonitor=false", "status", "--porcelain"], this.on)).out !== "";
          this.unpushed = (await submodules(repo.top, this.on)).unpushed;
        }
        if (repo && this.opening) this.list = await checkouts(repo, this.on);
        if (repo && !this.opening && props().action !== "remove") {
          // The base branch defaults to where this checkout is now.
          if (!this.baseText) {
            const cur = await git(repo.top, ["symbolic-ref", "--short", "-q", "HEAD"], this.on);
            this.baseText = cur.ok && cur.out ? cur.out : "HEAD";
            this.baseInput.set_value(this.baseText);
          }
          // A default script the repo kind suggests, when one is saved.
          let def = null;
          if (!this.on) {
            const has = async (f) => (await exec("sh", ["-c", '[ -f "$1/$2" ]', "x", repo.top, f])).code === 0;
            if ((await has("artisan")) || (await has("composer.json"))) def = "composer install";
            else if (await has("package.json")) def = "yarn install";
          }
          this.defaultCommand = def ?? "";
          this.applyDefaultScript();
          // Every local and remote branch, for the base field's suggestions.
          const refs = await git(repo.main, ["for-each-ref", "--format=%(refname:short)", "refs/heads", "refs/remotes"], this.on);
          this.branches = refs.out.split("\n").map((x) => x.trim()).filter((x) => x && !x.endsWith("/HEAD") && x !== "origin");
        }
        this.repo = repo;
        cx.notify();
        if (props().branch) await this.work(cx);
      } catch (error) { this.repo = null; this.error = String(error); cx.notify(); }
    });
  }

  applyDefaultScript() {
    if (this.defaultApplied || !this.scriptsLoaded || this.defaultCommand === undefined) return;
    this.defaultApplied = true;
    const at = this.scripts.findIndex((x) => x.command && x.command === this.defaultCommand);
    if (at > 0) this.scriptAt = at;
  }

  progress(text) {
    this.stepText = text;
    this.cx?.notify();
  }

  async saveCustom(cx) {
    const command = this.custom.trim();
    if (!command || this.scripts.some((x) => x.command === command)) return;
    const name = command.length > 36 ? `${command.slice(0, 35)}…` : command;
    const list = [...this.scripts.filter((x) => x.command), { name, command }];
    const text = JSON.stringify(list.map(({ name, command }) => ({ name, command })), null, 2);
    try { await writeTextFile(`${appHome()}/mods/greasy-panes-worktree/scripts.json`, text, this.scriptsRaw); }
    catch (error) { this.error = `Could not save the script: ${error}`; return cx.notify(); }
    this.scriptsRaw = text;
    this.scripts = [{ name: "No script" }, ...list, { name: "Custom…", custom: true }];
    this.scriptAt = list.length;
    this.customInput.set_value("");
    this.custom = "";
    cx.notify();
  }

  suggestions() {
    if (!this.baseFocused) return [];
    const f = this.baseText.trim().toLowerCase();
    const list = this.branches.filter((b) => !f || b.toLowerCase().includes(f));
    if (list.length === 1 && list[0] === this.baseText.trim()) return [];
    return list.slice(0, 6);
  }

  pick(branch, cx) {
    if (!branch) return;
    this.baseText = branch;
    this.baseInput.set_value(branch);
    this.sugTouched = false;
    this.sugAt = 0;
    cx.notify();
  }

  space() {
    const p = props() ?? {};
    return spaces().find((s) => s.id === p.space) ?? (p.folder ? { folder: p.folder, machine: p.machine ?? null, name: "" } : undefined);
  }

  close() {
    closeOverlay(props().overlay);
  }

  go(cx) {
    if (this.busy || !this.repo) return;
    cx.spawn(async (cx) => this.work(cx));
  }

  async work(cx) {
    if (this.busy || !this.repo) return;
    this.cx = cx;
    this.stepText = "";
    this.busy = true;
    this.error = "";
    cx.notify();
    try { this.error = props().action === "remove" ? await this.remove() : await this.create(); }
    catch (error) { this.error = String(error); }
    this.busy = false;
    if (!this.error) this.close();
    cx.notify();
  }

  async create() {
    const branch = this.text.trim();
    if (!branch) return "Type a branch name.";
    this.progress("Checking…");
    if (!(await git(this.repo.main, ["check-ref-format", "--branch", branch], this.on)).ok) return `"${branch}" is not a valid branch name.`;
    const path = `${ROOT(this.userHome)}/${this.repo.name}/${slug(branch)}`;
    const listed = await git(this.repo.main, ["worktree", "list", "--porcelain"], this.on);
    let at = "";
    for (const line of listed.out.split("\n")) {
      if (line.startsWith("worktree ")) at = line.slice(9);
      else if (line === `branch refs/heads/${branch}`) return `Branch ${branch} is already checked out in ${tilde(at, this.userHome)}.`;
    }
    if ((await exec("sh", ["-c", '[ -e "$1" ]', "x", path], { on: this.on })).code === 0) return `Folder already exists: ${tilde(path, this.userHome)}.`;
    const exists = (await git(this.repo.main, ["show-ref", "--verify", "--quiet", `refs/heads/${branch}`], this.on)).ok;
    const base = this.baseText.trim() || "HEAD";
    if (!exists) {
      // A base that names a remote branch is fetched first, so a new branch
      // can start from work that isn't cloned yet.
      const m = base.match(/^([^/]+)\/(.+)$/);
      const remotes = (await git(this.repo.main, ["remote"], this.on)).out.split("\n").map((x) => x.trim());
      if (m && remotes.includes(m[1])) {
        this.progress(`Fetching ${base}…`);
        await git(this.repo.main, ["fetch", m[1], m[2]], this.on, 60_000);
      }
    }
    if (!exists && !(await git(this.repo.main, ["rev-parse", "--verify", "--quiet", `${base}^{commit}`], this.on)).ok) return `Base "${base}" not found.`;
    this.progress("Creating worktree…");
    const add = exists ? ["worktree", "add", path, branch] : ["worktree", "add", "-b", branch, path, base];
    const r = await git(this.repo.top, add, this.on, 600_000);
    if (!r.ok) return r.err || "git worktree add failed.";
    const p = props();
    // Leave spaces unnamed so they follow the checkout folder and nest under the repo.
    this.progress("Opening space…");
    const script = this.scripts[this.scriptAt];
    const command = script?.custom ? this.custom.trim() : script?.command;
    const argv = command ? ["sh", "-c", command] : p.argv;
    run("space.new", { folder: path, machine: this.on, tab: p.tab, argv });
    return "";
  }

  shown() {
    const f = this.text.trim().toLowerCase();
    return (this.list ?? []).filter((c) => !f || `${c.branch ?? ""} ${c.path}`.toLowerCase().includes(f));
  }

  open(c) {
    if (!c) return;
    this.close();
    const s = spaceOf(c.path, this.list, this.on);
    if (s) run("space.select", { id: s.id });
    else run("space.new", { folder: c.path, machine: this.on });
  }

  async remove() {
    const s = this.space();
    const status = await git(this.repo.top, ["--no-optional-locks", "-c", "core.fsmonitor=false", "status", "--porcelain"], this.on);
    if (!status.ok) return status.err || "git status failed.";
    // git refuses a worktree with submodules unless forced, because their
    // history goes with it. The popup already showed what's at risk; only
    // risk that appeared since it opened gets one more warning.
    const { mods, unpushed } = await submodules(this.repo.top, this.on);
    const changed = (status.out && !this.dirty) || unpushed.some((name) => !this.unpushed.includes(name));
    this.dirty ||= status.out !== "";
    this.unpushed = [...new Set([...this.unpushed, ...unpushed])];
    if (changed) return "It changed since this opened. Enter again removes it anyway.";
    // Terminals first: a shell sitting in the folder keeps it busy on Windows.
    run("space.close", { id: s.id, confirmed: true });
    const force = this.dirty || mods.length > 0;
    const r = await git(this.repo.main, ["worktree", "remove", ...(force ? ["--force"] : []), this.repo.top], this.on);
    return r.ok ? "" : r.err || "git worktree remove failed.";
  }

  key(e, cx) {
    // The base field's suggestion list: arrows move through it, enter picks
    // (the field's submit does that). Tab never picks — it cycles fields.
    if (!this.opening && this.baseFocused) {
      const sug = this.suggestions();
      if (sug.length && (e.key === "down" || e.key === "up")) {
        this.sugTouched = true;
        this.sugAt = (this.sugAt + (e.key === "down" ? 1 : sug.length - 1)) % sug.length;
        cx.stop_propagation();
        return cx.notify();
      }
    }
    // The startup script trigger's keyboard focus: enter or down opens the
    // dropdown, arrows choose, enter picks; tab moves on (the cycle below
    // closes the dropdown when leaving).
    if (!this.opening && this.scriptFocused) {
      if (!this.scriptOpen && (e.key === "enter" || e.key === "down")) {
        this.scriptOpen = true;
        cx.notify();
        return cx.stop_propagation();
      }
      if (this.scriptOpen) {
        const n = this.scripts.length;
        if (e.key === "down" || e.key === "up") {
          this.scriptAt = (this.scriptAt + (e.key === "down" ? 1 : n - 1)) % n;
          cx.notify();
          return cx.stop_propagation();
        }
        if (e.key === "enter") {
          const sc = this.scripts[this.scriptAt];
          this.scriptOpen = false;
          this.scriptFocused = false;
          cx.notify();
          if (sc?.custom) cx.timer.after(50, () => this.customInput.focus());
          return cx.stop_propagation();
        }
      }
    }
    // tab / shift-tab cycle the dialog's fields (branch, base, the startup
    // script trigger, and the custom command while it is shown), wrapping.
    // Only when the fields are on screen: the new-worktree dialog with its
    // repo found.
    if (e.key === "tab" && !this.opening && props()?.action !== "remove" && this.repo) {
      const customShown = this.scripts[this.scriptAt]?.custom && !this.scriptOpen;
      const fields = [this.input, this.baseInput, "script", ...(customShown ? [this.customInput] : [])];
      const focused = this.inputFocused ? 0 : this.baseFocused ? 1 : this.scriptFocused ? 2 : customShown && this.customFocused ? 3 : -1;
      const next = focused === -1
        ? (e.modifiers.shift ? fields.length - 1 : 0)
        : (focused + (e.modifiers.shift ? fields.length - 1 : 1)) % fields.length;
      const to = fields[next];
      // Leaving the base field ends its suggestion browsing.
      if (focused === 1) this.sugTouched = false;
      if (to === "script") {
        // The keyboard moves onto the dialog itself (the inputs blur
        // normally, so their focus flags and the suggestion list reset).
        this.handle.focus();
        this.scriptFocused = true;
      } else {
        this.scriptOpen = false;
        this.scriptFocused = false;
        to.focus();
      }
      return cx.stop_propagation();
    }
    if (e.key === "escape") return this.close();
    if (this.opening) {
      const n = this.shown().length;
      if (e.key === "enter") this.open(this.shown()[this.at]);
      else if ((e.key === "down" || e.key === "up") && n) this.at = (this.at + (e.key === "down" ? 1 : n - 1)) % n;
      else return;
      cx.stop_propagation();
      return cx.notify();
    }
    if (e.key === "enter" && props()?.action === "remove") return this.go(cx);
  }

  renderOpen(t) {
    const r = this.repo;
    const rows = this.shown();
    const all = this.list ?? [];
    const row = (c, i) => {
      const on = i === this.at;
      const there = spaceOf(c.path, all, this.on);
      return v_flex()
        .id(`wt-${i}`)
        .flex_none()
        .h(44)
        .px(10)
        .justify_center()
        .rounded(7)
        .cursor_pointer()
        .when(on, (el) => el.bg(t.selected))
        .when(!on, (el) => el.hover((s) => s.bg(t.hover)))
        .on_click(() => this.open(c))
        .child(
          h_flex()
            .gap(8)
            .items_center()
            .child(div().flex_1().min_w(0).truncate().text_color(t.foreground).child(c.branch ?? "detached"))
            .when(c.main, (el) => el.child(div().flex_none().text_size(11).text_color(t.dim).child("main checkout")))
            .when(Boolean(there), (el) => el.child(div().flex_none().text_size(11).text_color(t.accent).child("open")))
            .when(!there && c.at > 0, (el) => el.child(div().flex_none().text_size(11).text_color(t.dim).child(ago(c.at)))),
        )
        .child(div().truncate().text_size(11.5).text_color(t.dim).child(tilde(c.path, this.userHome ?? "")));
    };
    const count = rows.length === all.length ? `${all.length} checkouts` : `${rows.length}/${all.length} checkouts`;
    return v_flex()
      .id("worktree")
      .track_focus(this.handle)
      .on_key_down((e, cx) => this.key(e, cx))
      .size_full()
      .p(16)
      .gap(10)
      .rounded(6).border_1().border_color(t.border).bg(shade(t.popover, "c7"))
      .text_size(13)
      .child(h_flex().child(div().flex_1().font_semibold().text_color(t.foreground).child(`Open worktree${r ? ` of ${r.name}` : ""}`)).child(div().text_size(11).text_color(t.dim).child(r ? count : "")))
      .when(r === undefined || (r && this.list === undefined), (el) => el.child(div().text_color(t.muted).child("\u2026")))
      .when(r === null, (el) => el.child(div().text_color(t.muted).child(`${this.folder ? tilde(this.folder, this.userHome ?? "") : "This folder"} is not in a git repository.`)))
      .when(Boolean(r && this.list), (el) =>
        el
          .child(Input.new(this.input).h(32).px(10).items_center().rounded(6).border(1).border_color(this.inputFocused ? t.accent : t.input).bg(t.background).text_color(t.foreground))
          .child(
            div()
              .relative()
              .flex_1()
              .min_h(0)
              .child(
                v_flex()
                  .id("wt-list")
                  .size_full()
                  .overflow_y_scroll()
                  .children(rows.map(row))
                  .when(rows.length === 0, (el) => el.child(div().p(10).text_color(t.dim).child("No matching worktrees."))),
              )
              .child(Scrollbar.vertical("wt-list").absolute().inset_0()),
          ),
      )
      .child(h_flex().justify_end().text_size(11).text_color(t.dim).child("\u2191\u2193 choose \u00b7 \u21b5 open \u00b7 esc close"));
  }

  render(cx) {
    const t = theme();
    if (this.opening) return this.renderOpen(t);
    const remove = props()?.action === "remove";
    const s = this.space();
    const r = this.repo;
    const title = remove ? `Remove worktree ${s?.name ?? ""}?` : `New worktree${r ? ` of ${r.name}` : ""}`;
    const detail =
      r === undefined
        ? "…"
        : r === null
          ? `${this.folder ? tilde(this.folder, this.userHome) : "This folder"} is not in a git repository.`
          : remove
            ? !r.linked
              ? "This is the repository's main checkout, not a worktree."
              : `Closes the space and deletes ${tilde(r.top, this.userHome)}. The branch stays.`
            : `A new space on a checkout in ${tilde(ROOT(this.userHome), this.userHome)}/${r.name}/. A branch that exists is checked out; a new one starts from the base branch.`;
    const blocked = !r || (remove && !r.linked);
    return v_flex()
      .id("worktree")
      .track_focus(this.handle)
      .on_key_down((e, cx) => this.key(e, cx))
      .size_full()
      .p(16)
      .gap(10)
      .rounded(6).border_1().border_color(t.border).bg(shade(t.popover, "c7"))
      .text_size(13)
      .child(div().font_semibold().text_color(t.foreground).child(title))
      .child(div().text_color(t.muted).child(detail))
      .when(remove && this.dirty, (el) => el.child(div().text_color(t.blocked).child("It has uncommitted changes: they will be lost.")))
      .when(remove && this.unpushed.length > 0, (el) => el.child(div().text_color(t.blocked).child(`Submodule ${this.unpushed.join(", ")} has commits that aren't pushed anywhere: they will be lost.`)))
      .when(!remove && !blocked, (el) =>
        el
          .child(label(t, "Git branch", "created, or checked out if it already exists"))
          .child(
            Input.new(this.input)
              .h(32)
              .px(10)
              .items_center()
              .rounded(6)
              .border(1)
              .border_color(this.inputFocused ? t.accent : t.input)
              .bg(t.background)
              .text_color(t.foreground),
          )
          .child(label(t, "Base branch", "new branches start from here"))
          .child(
            Input.new(this.baseInput)
              .h(32)
              .px(10)
              .items_center()
              .rounded(6)
              .border(1)
              .border_color(this.baseFocused ? t.accent : t.input)
              .bg(t.background)
              .text_color(t.foreground),
          )
          .when(this.suggestions().length > 0, (e) =>
            e.child(
              v_flex()
                .rounded(6)
                .border(1)
                .border_color(t.border)
                .bg(t.popover)
                .children(
                  this.suggestions().map((b, i) =>
                    div()
                      .id(`base-${i}`)
                      .h(26)
                      .px(10)
                      .flex()
                      .items_center()
                      .text_size(12)
                      .text_color(i === this.sugAt && this.sugTouched ? t.foreground : t.muted)
                      .bg(i === this.sugAt && this.sugTouched ? t.selected : t.popover)
                      .hover((x) => x.bg(t.hover))
                      .on_mouse_down("left", (_e, cx) => { cx.stop_propagation(); this.pick(b, cx); })
                      .child(b),
                  ),
                ),
            ),
          )
          .child(label(t, "Startup script", "runs in the new space's terminal"))
          .child(
            h_flex()
              .id("script-trigger")
              .h(32)
              .px(10)
              .items_center()
              .justify_between()
              .rounded(6)
              .border(1)
              .border_color(this.scriptFocused || this.scriptOpen ? t.accent : t.input)
              .bg(t.background)
              .text_color(this.scriptAt ? t.foreground : t.muted)
              .hover((st) => st.bg(t.hover))
              .on_click((_e, cx) => { this.handle.focus(); this.scriptFocused = true; this.scriptOpen = !this.scriptOpen; cx.notify(); })
              .child(this.scripts[this.scriptAt]?.name ?? "No script")
              .child(svg("mods/workspace-chrome/chevron-down.svg").size(14).text_color(t.dim)),
          )
          .when(this.scripts[this.scriptAt]?.custom && !this.scriptOpen, (e) =>
            e.child(
              h_flex()
                .gap(6)
                .child(
                  Input.new(this.customInput)
                    .h(32)
                    .flex_1()
                    .px(10)
                    .items_center()
                    .rounded(6)
                    .border(1)
                    .border_color(this.customFocused ? t.accent : t.input)
                    .bg(t.background)
                    .text_color(t.foreground),
                )
                .when(this.custom.trim() && !this.scripts.some((x) => x.command === this.custom.trim()), (row) =>
                  row.child(
                    div()
                      .id("save-script")
                      .h(32)
                      .px(10)
                      .flex()
                      .items_center()
                      .rounded(6)
                      .border(1)
                      .border_color(t.input)
                      .text_size(12)
                      .text_color(t.muted)
                      .hover((x) => x.bg(t.hover))
                      .on_click((_e, cx) => cx.spawn(async (cx) => this.saveCustom(cx)))
                      .child("save"),
                  ),
                ),
            ),
          )
          .when(this.scriptOpen, (e) =>
            e.child(
              v_flex()
                .rounded(6)
                .border(1)
                .border_color(t.border)
                .bg(t.popover)
                .children(
                  this.scripts.map((sc, i) =>
                    div()
                      .id(`script-${i}`)
                      .h(28)
                      .px(10)
                      .flex()
                      .items_center()
                      .text_color(i === this.scriptAt ? t.foreground : t.muted)
                      .bg(i === this.scriptAt ? t.selected : t.popover)
                      .hover((x) => x.bg(t.hover))
                      .on_click((_e, cx) => { this.scriptAt = i; this.scriptOpen = false; cx.notify(); if (sc.custom) cx.timer.after(50, () => this.customInput.focus()); })
                      .child(sc.name),
                  ),
                ),
            ),
          ),
      )
      .when(Boolean(this.error), (el) => el.child(div().text_color(t.blocked).child(this.error)))
      .child(div().flex_1())
      .child(
        h_flex()
          .justify_end()
          .text_size(11)
          .text_color(t.dim)
          .gap(6)
          .when(this.busy, (el) => el.child(div().frames(["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"], 90)))
          .child(this.busy ? this.stepText || "working…" : blocked ? "esc close" : remove ? "↵ remove · esc cancel" : "↵ create · esc cancel"),
      );
  }
}
