import { BUNNIES, bunnyByMonth, charmSvg, markSvg } from "./bunnies.js";
import { todayInspiration } from "./inspire.js";
import { defaultCircle, fellowCards, encodeCard, decodeCard, sparkSvg } from "./circle.js";

const STORAGE_KEY = "white-rabbits-v2";
const LEGACY_KEY = "white-rabbits-v1";
const MOODS = ["Calm", "Clear", "Tender", "Tired", "Lucky"];
const DEFAULT_HABITS = [
  { id: "light", name: "Morning light" },
  { id: "water", name: "A glass of water" },
  { id: "write", name: "Write a few lines" },
  { id: "outside", name: "Step outside" },
];
const INTENTIONS = [
  "Begin with softness",
  "Protect the quiet hours",
  "Make one true thing",
  "Leave room for luck",
  "Keep the mornings slow",
];

const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
const params = new URLSearchParams(location.search);

const els = {
  kicker: document.getElementById("header-kicker"),
  settingsOpen: document.getElementById("settings-open"),
  preview: document.getElementById("preview-pill"),
  home: document.getElementById("view-home"),
  charms: document.getElementById("view-charms"),
  journal: document.getElementById("view-journal"),
  circle: document.getElementById("view-circle"),
  ritual: document.getElementById("ritual-overlay"),
  sheet: document.getElementById("sheet-layer"),
};

const kickers = {
  home: "Today",
  journal: "Journal",
  charms: "Charms",
  circle: "Shared Sanctuary",
};

let tab = "home";
let audioCtx = null;
let recognition = null;
let installPrompt = null;
let greetingOffered = false;

let state = loadState();
if (params.has("first")) state.previewFirst = true;

applyTheme();

function defaultState() {
  return {
    haptics: true,
    previewFirst: false,
    theme: "light",
    habits: DEFAULT_HABITS.map((habit) => ({ ...habit })),
    checks: {},
    journal: {},
    months: {},
    name: "",
    welcomed: false,
    circle: defaultCircle(),
  };
}

function loadState() {
  const base = defaultState();
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (raw) {
      const parsed = JSON.parse(raw);
      return {
        ...base,
        ...parsed,
        circle: { ...base.circle, ...(parsed.circle ?? {}) },
      };
    }
    const legacy = localStorage.getItem(LEGACY_KEY);
    if (legacy) {
      const old = JSON.parse(legacy);
      return {
        ...base,
        months: old.months ?? {},
        haptics: old.haptics ?? true,
        previewFirst: old.previewFirst ?? false,
      };
    }
  } catch { /* start clean */ }
  return base;
}

function save() {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
  } catch {
    const slim = structuredClone(state);
    Object.values(slim.journal).forEach((entry) => {
      if (entry.photo?.length > 100000) entry.photo = "";
    });
    try { localStorage.setItem(STORAGE_KEY, JSON.stringify(slim)); } catch { /* quota */ }
  }
}

function backupPayload() {
  return {
    app: "white-rabbits",
    v: 1,
    exported: new Date().toISOString(),
    journal: state.journal ?? {},
    checks: state.checks ?? {},
    months: state.months ?? {},
    habits: state.habits ?? [],
    name: state.name ?? "",
    welcomed: Boolean(state.welcomed),
    theme: state.theme === "dark" ? "dark" : "light",
    haptics: Boolean(state.haptics),
    circle: circleState(),
  };
}

function exportData() {
  haptic(8);
  const blob = new Blob([JSON.stringify(backupPayload(), null, 2)], { type: "application/json" });
  const today = new Date();
  const stamp = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, "0")}-${String(today.getDate()).padStart(2, "0")}`;
  const link = document.createElement("a");
  link.href = URL.createObjectURL(blob);
  link.download = `white-rabbits-${stamp}.json`;
  link.click();
  URL.revokeObjectURL(link.href);
}

function applyBackup(data) {
  if (!data || typeof data !== "object" || Array.isArray(data)) return false;
  const source = data.journal || data.checks || data.months ? data : null;
  if (!source) return false;
  const base = defaultState();
  state = {
    ...base,
    journal: source.journal && typeof source.journal === "object" && !Array.isArray(source.journal) ? source.journal : {},
    checks: source.checks && typeof source.checks === "object" && !Array.isArray(source.checks) ? source.checks : {},
    months: source.months && typeof source.months === "object" && !Array.isArray(source.months) ? source.months : {},
    habits: Array.isArray(source.habits) && source.habits.length ? source.habits : base.habits,
    name: typeof source.name === "string" ? source.name : "",
    welcomed: source.welcomed ?? Boolean(source.name),
    theme: source.theme === "dark" ? "dark" : "light",
    haptics: typeof source.haptics === "boolean" ? source.haptics : true,
    previewFirst: false,
    circle: { ...base.circle, ...(source.circle && typeof source.circle === "object" ? source.circle : {}) },
  };
  save();
  applyTheme();
  greetingOffered = false;
  return true;
}

async function importBackupFile(file) {
  if (!file) return;
  try {
    const data = JSON.parse(await file.text());
    if (!applyBackup(data)) throw new Error("shape");
    haptic([10, 24, 14]);
    closeOverlay(els.sheet);
    render();
  } catch {
    openOverlay(els.sheet, `
      <section class="sheet" role="dialog" aria-labelledby="backup-title">
        <div class="handle"></div>
        <p class="kicker">Backup</p>
        <h2 id="backup-title">This file could not be restored.</h2>
        <p class="lede">Use a White Rabbits JSON export. Nothing on this phone was changed.</p>
        <button class="primary" type="button" data-act="settings">Back to settings</button>
      </section>
    `);
  }
}

function applyTheme() {
  document.documentElement.dataset.theme = state.theme;
  const meta = document.getElementById("theme-color");
  if (meta) meta.setAttribute("content", state.theme === "dark" ? "#161412" : "#F6F1EA");
}

function now() {
  const d = new Date();
  if (state.previewFirst) return new Date(d.getFullYear(), d.getMonth(), 1, d.getHours(), d.getMinutes(), d.getSeconds());
  return d;
}

function monthKey(date = now()) {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}`;
}

function dayKey(date = now()) {
  return `${monthKey(date)}-${String(date.getDate()).padStart(2, "0")}`;
}

function monthName(date = now()) {
  return new Intl.DateTimeFormat("en-GB", { month: "long" }).format(date);
}

function dayLabel(key) {
  const [y, m, d] = key.split("-").map(Number);
  return new Intl.DateTimeFormat("en-GB", { weekday: "long", day: "numeric", month: "long" }).format(new Date(y, m - 1, d));
}

function currentBunny(date = now()) {
  return bunnyByMonth(date.getMonth() + 1);
}

function currentMonth() {
  return state.months[monthKey()];
}

function isFirstMorning(date = now()) {
  return date.getDate() === 1;
}

function ritualDone() {
  return Boolean(currentMonth()?.completed);
}

function unlockedIds() {
  return new Set(
    Object.values(state.months)
      .filter((entry) => entry.completed && entry.charmId)
      .map((entry) => entry.charmId),
  );
}

function yearMonthKey(month, year = now().getFullYear()) {
  return `${year}-${String(month).padStart(2, "0")}`;
}

function monthPages(month, year = now().getFullYear()) {
  const prefix = yearMonthKey(month, year);
  return Object.entries(state.journal)
    .filter(([key, entry]) => key.startsWith(prefix) && pageHasContent(entry))
    .sort((a, b) => a[0].localeCompare(b[0]));
}

function pageHasContent(entry) {
  return Boolean(entry?.text?.trim() || entry?.photo || entry?.mood);
}

function persistPage(key, { text = "", mood = "", photo = "" }) {
  const clean = {
    text: String(text ?? "").trim(),
    mood: mood || "",
    photo: photo || "",
    updated: new Date().toISOString(),
  };
  if (!pageHasContent(clean)) {
    delete state.journal[key];
  } else {
    state.journal[key] = { ...(state.journal[key] ?? {}), ...clean };
    if (clean.text && key === dayKey()) {
      const write = state.habits.find((habit) => /write/i.test(habit.name));
      if (write) {
        const set = todayChecks();
        set.add(write.id);
        state.checks[key] = [...set];
      }
    }
  }
  save();
}

function showJournal() {
  closeOverlay(els.sheet);
  closeOverlay(els.ritual);
  if (tab !== "journal") setTab("journal");
  else render();
}

function lastMonthArchive(date = now()) {
  const prev = new Date(date.getFullYear(), date.getMonth() - 1, 1);
  const month = prev.getMonth() + 1;
  const year = prev.getFullYear();
  return {
    month,
    year,
    label: monthName(prev),
    bunny: bunnyByMonth(month),
    pages: monthPages(month, year),
    ritual: state.months[yearMonthKey(month, year)],
  };
}

function hasArchive(archive = lastMonthArchive()) {
  return Boolean(archive.pages.length || archive.ritual?.completed || archive.ritual?.intention);
}

function inHandoff(date = now()) {
  return date.getDate() <= 7;
}

function noteCardHtml(key, entry) {
  const line = entry.text?.trim() || (entry.photo ? "A photograph for this day." : entry.mood || "A quiet mark.");
  return `
    <button class="note-card ${entry.photo ? "has-photo" : ""}" type="button" data-compose="${key}">
      ${entry.photo ? `<img src="${entry.photo}" alt="">` : ""}
      <span>
        <p class="kicker">${dayLabel(key)}</p>
        <p>${escapeHtml(line)}</p>
        ${entry.mood ? `<span class="mood">${escapeHtml(entry.mood)}</span>` : ""}
      </span>
    </button>
  `;
}

function monthCalendarHtml(month, year) {
  const first = new Date(year, month - 1, 1);
  const count = new Date(year, month, 0).getDate();
  const pad = (first.getDay() + 6) % 7;
  const today = dayKey();
  const cells = Array.from({ length: pad }, () => `<span class="cal-empty"></span>`);
  for (let day = 1; day <= count; day += 1) {
    const key = `${yearMonthKey(month, year)}-${String(day).padStart(2, "0")}`;
    const filled = pageHasContent(state.journal[key]);
    const isToday = key === today;
    if (filled || isToday) {
      cells.push(`<button class="cal-day ${filled ? "is-on" : ""} ${isToday ? "is-today" : ""}" type="button" data-compose="${key}" aria-label="${dayLabel(key)}${filled ? ", a page kept" : ""}">${day}</button>`);
    } else {
      cells.push(`<span class="cal-day">${day}</span>`);
    }
  }
  return `
    <article class="cal" aria-label="${monthName(first)} calendar">
      <div class="cal-week">${["M", "T", "W", "T", "F", "S", "S"].map((d) => `<span>${d}</span>`).join("")}</div>
      <div class="cal-grid">${cells.join("")}</div>
    </article>
  `;
}

function journalMonthGroups() {
  const groups = new Map();
  Object.entries(state.journal).forEach(([key, entry]) => {
    if (!pageHasContent(entry)) return;
    const prefix = key.slice(0, 7);
    if (!groups.has(prefix)) groups.set(prefix, []);
    groups.get(prefix).push([key, entry]);
  });
  return [...groups.entries()]
    .sort((a, b) => b[0].localeCompare(a[0]))
    .map(([prefix, pages]) => {
      const [year, month] = prefix.split("-").map(Number);
      pages.sort((a, b) => b[0].localeCompare(a[0]));
      return { prefix, year, month, bunny: bunnyByMonth(month), label: monthName(new Date(year, month - 1, 1)), pages, ritual: state.months[prefix] };
    });
}

function stampState(month, year = now().getFullYear()) {
  const nowDate = now();
  const currentMonth = nowDate.getMonth() + 1;
  const currentYear = nowDate.getFullYear();
  const ritual = state.months[yearMonthKey(month, year)];
  const pages = monthPages(month, year);
  const collected = Boolean(ritual?.completed);
  return {
    year,
    month,
    bunny: bunnyByMonth(month),
    ritual,
    pages,
    collected,
    current: year === currentYear && month === currentMonth,
    upcoming: year > currentYear || (year === currentYear && month > currentMonth),
  };
}

function inspireHtml() {
  const item = todayInspiration(now());
  return `
    <article class="inspire">
      <p class="kicker">${item.kicker}</p>
      <p class="inspire-line">${item.line}</p>
      <p class="inspire-prompt">${item.prompt}</p>
    </article>
  `;
}

function journalInviteHtml(note) {
  return `
    <article class="journal-invite">
      <p class="kicker">${firstName() ? `Today’s page, ${escapeHtml(firstName())}` : "Today’s page"}</p>
      <p class="invite-copy">Whenever it feels right... write, drop a photo, or voice-note your thoughts.</p>
      <div class="invite-actions">
        <button type="button" class="invite-act" data-act="compose">
          <svg viewBox="0 0 18 18" fill="none" stroke="currentColor" stroke-width="1.4"><path d="M4 14.5l.8-3.2L12.6 3.5a1.4 1.4 0 012 2L6.8 13.3 3.5 14.5z"/><path d="M11.2 5.1l1.8 1.8"/></svg>
          Write
        </button>
        <button type="button" class="invite-act" data-act="journal-photo">
          <svg viewBox="0 0 18 18" fill="none" stroke="currentColor" stroke-width="1.4"><rect x="2.5" y="4.5" width="13" height="10" rx="1.6"/><circle cx="7" cy="8.4" r="1.3"/><path d="M6.2 14.5l3.2-3.4 2.2 2.2 2.4-2.8 1.5 4"/></svg>
          Photo
        </button>
        <button type="button" class="invite-act ${canListen() ? "" : "is-off"}" data-act="voice" aria-label="Voice note, transcribed to text">
          <svg viewBox="0 0 18 18" fill="none" stroke="currentColor" stroke-width="1.5"><rect x="6.2" y="2.4" width="5.6" height="8.4" rx="2.8"/><path d="M4.4 8.8a4.6 4.6 0 009.2 0M9 13.4V16"/></svg>
          Voice
        </button>
      </div>
      <p class="live-transcript" id="live-transcript" hidden></p>
      ${note?.text || note?.photo ? `
        <button class="note-preview" data-act="compose">
          ${note.photo ? `<img src="${note.photo}" alt="">` : ""}
          <span>${note.text ? escapeHtml(note.text) : "A photograph for today."}</span>
        </button>
      ` : ""}
    </article>
  `;
}

function stampCardHtml() {
  const year = now().getFullYear();
  const collected = BUNNIES.filter((bunny) => stampState(bunny.month).collected).length;
  return `
    <article class="stamp-card" aria-label="Twelve month stamp card">
      <div class="stamp-head">
        <div>
          <p class="kicker">${firstName() ? `For ${escapeHtml(firstName())}` : year}</p>
          <strong>Year of luck</strong>
        </div>
        <span class="kicker">${collected} of 12</span>
      </div>
      <div class="stamp-board">
        ${BUNNIES.map((bunny) => {
          const slot = stampState(bunny.month);
          const status = slot.collected ? "collected" : slot.current ? "this month, waiting" : slot.upcoming ? "upcoming" : "unmarked";
          return `
            <button class="stamp ${slot.collected ? "is-open" : ""} ${slot.current ? "is-now" : ""}" data-stamp="${bunny.month}" aria-label="${bunny.season}, ${bunny.name}, ${status}">
              <span class="slot">${charmSvg(bunny, slot.collected)}</span>
              <span class="label">${bunny.season.slice(0, 3)}</span>
            </button>
          `;
        }).join("")}
      </div>
    </article>
  `;
}

function todayChecks() {
  return new Set(state.checks[dayKey()] ?? []);
}

function weekDots(habitId) {
  const d = now();
  const start = new Date(d);
  start.setDate(d.getDate() - ((d.getDay() + 6) % 7));
  return Array.from({ length: 7 }, (_, i) => {
    const day = new Date(start);
    day.setDate(start.getDate() + i);
    return (state.checks[dayKey(day)] ?? []).includes(habitId);
  });
}

function monthKept(habitId) {
  const prefix = monthKey();
  return Object.entries(state.checks)
    .filter(([key, ids]) => key.startsWith(prefix) && ids.includes(habitId))
    .length;
}

function growthCopy(habitId, onToday) {
  const week = weekDots(habitId).filter(Boolean).length;
  const month = monthKept(habitId);
  if (onToday) {
    if (week >= 5) return "A generous week";
    if (week >= 3) return "Growing, gently";
    return "A quiet yes";
  }
  if (month === 0) return "Whenever you like";
  return `${month} kept this month`;
}

function greetingCopy() {
  const hour = now().getHours();
  if (hour < 12) return "Good morning";
  if (hour < 18) return "Good afternoon";
  return "Good evening";
}

function firstName() {
  return String(state.name ?? "").trim();
}

function circleState() {
  const base = defaultCircle();
  if (!state.circle || typeof state.circle !== "object") state.circle = { ...base };
  state.circle = {
    ...base,
    ...state.circle,
    friends: Array.isArray(state.circle.friends) ? state.circle.friends : [],
    sparksGiven: state.circle.sparksGiven && typeof state.circle.sparksGiven === "object" ? state.circle.sparksGiven : {},
    sparksReceived: Array.isArray(state.circle.sparksReceived) ? state.circle.sparksReceived : [],
  };
  if (!state.circle.id) {
    state.circle.id = `wr_${crypto.randomUUID?.() || `${Date.now().toString(36)}${Math.random().toString(36).slice(2, 8)}`}`;
  }
  return state.circle;
}

function publicCard() {
  const ritual = currentMonth();
  if (!ritual?.intention) return null;
  const bunny = currentBunny();
  return {
    id: circleState().id,
    name: firstName() || "A friend",
    month: now().getMonth() + 1,
    year: now().getFullYear(),
    intention: ritual.intention,
    charmId: ritual.charmId || bunny.id,
    kind: "you",
  };
}

function sparkKey(id) {
  return `${id}:${monthKey()}`;
}

function hasSparked(id) {
  return Boolean(circleState().sparksGiven[sparkKey(id)]);
}

function unseenSparks() {
  const key = monthKey();
  return circleState().sparksReceived.filter((item) => item.monthKey === key && !item.seen);
}

function maybeArriveSpark() {
  const circle = circleState();
  if (!circle.joined || !currentMonth()?.intention) return;
  const key = monthKey();
  if (circle.sparksReceived.some((item) => item.monthKey === key)) return;
  const fellow = fellowCards(now())[0];
  circle.sparksReceived.push({
    from: fellow.id,
    name: fellow.name,
    at: new Date().toISOString(),
    monthKey: key,
    seen: false,
  });
  save();
}

function sparkChime() {
  if (reduced) return;
  const ctx = ensureAudio();
  const osc = ctx.createOscillator();
  const gain = ctx.createGain();
  osc.type = "sine";
  osc.frequency.value = 880;
  const t = ctx.currentTime;
  gain.gain.setValueAtTime(0, t);
  gain.gain.linearRampToValueAtTime(0.04, t + 0.02);
  gain.gain.exponentialRampToValueAtTime(0.001, t + 0.7);
  osc.connect(gain).connect(ctx.destination);
  osc.start(t);
  osc.stop(t + 0.75);
}

function sanctuaryGreeting(first = false) {
  const n = firstName();
  const hi = greetingCopy();
  const month = monthName();
  if (first) {
    return n ? `${hi}, ${n}. ${month} has arrived.` : `${hi}. ${month} has arrived.`;
  }
  return n ? `${hi}, ${n}. ${month} is yours.` : `${hi}. ${month} is still unfolding.`;
}

function haptic(pattern = 12) {
  if (!state.haptics || !navigator.vibrate) return;
  navigator.vibrate(pattern);
}

function ensureAudio() {
  if (!audioCtx) audioCtx = new (window.AudioContext || window.webkitAudioContext)();
  if (audioCtx.state === "suspended") audioCtx.resume();
  return audioCtx;
}

function chime() {
  if (reduced) return;
  const ctx = ensureAudio();
  [523.25, 659.25, 783.99].forEach((freq, i) => {
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = "sine";
    osc.frequency.value = freq;
    const t = ctx.currentTime + i * 0.16;
    gain.gain.setValueAtTime(0, t);
    gain.gain.linearRampToValueAtTime(0.07, t + 0.03);
    gain.gain.exponentialRampToValueAtTime(0.001, t + 1.35);
    osc.connect(gain).connect(ctx.destination);
    osc.start(t);
    osc.stop(t + 1.45);
  });
}

function canListen() {
  return "SpeechRecognition" in window || "webkitSpeechRecognition" in window;
}

function startListening(onHeard) {
  const Ctor = window.SpeechRecognition || window.webkitSpeechRecognition;
  if (!Ctor) return;
  stopListening();
  recognition = new Ctor();
  recognition.lang = "en-GB";
  recognition.interimResults = true;
  recognition.continuous = true;
  recognition.onresult = (event) => {
    const text = [...event.results].map((r) => r[0].transcript).join(" ").toLowerCase();
    if (text.includes("white rabbit")) onHeard();
  };
  recognition.start();
}

function startDictation(onText) {
  const Ctor = window.SpeechRecognition || window.webkitSpeechRecognition;
  if (!Ctor) return false;
  stopListening();
  recognition = new Ctor();
  recognition.lang = "en-GB";
  recognition.interimResults = true;
  recognition.continuous = true;
  recognition.onresult = (event) => {
    const text = [...event.results].map((r) => r[0].transcript).join(" ").trim();
    if (text) onText(text);
  };
  recognition.onend = () => {
    document.querySelectorAll(".voice-btn, [data-act='voice']").forEach((btn) => btn.classList.remove("is-on"));
    const live = document.getElementById("live-transcript");
    const spoken = live?.textContent.trim();
    if (!live || live.hidden || !spoken) return;
    if (spoken.startsWith("Listening...")) return;
    live.hidden = true;
    live.textContent = "";
    appendJournalText(spoken);
  };
  recognition.start();
  return true;
}

function stopListening() {
  try { recognition?.stop(); } catch { /* ended */ }
  recognition = null;
}

function compressImage(file) {
  return new Promise((resolve, reject) => {
    const img = new Image();
    const url = URL.createObjectURL(file);
    img.onload = () => {
      const canvas = document.createElement("canvas");
      const max = 1200;
      let { width: w, height: h } = img;
      if (w > h && w > max) { h = (h * max) / w; w = max; }
      else if (h > max) { w = (w * max) / h; h = max; }
      canvas.width = w;
      canvas.height = h;
      canvas.getContext("2d").drawImage(img, 0, 0, w, h);
      URL.revokeObjectURL(url);
      resolve(canvas.toDataURL("image/jpeg", 0.76));
    };
    img.onerror = reject;
    img.src = url;
  });
}

function escapeHtml(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

function setTab(next) {
  tab = next;
  haptic(8);
  document.querySelectorAll("[data-tab]").forEach((btn) => {
    const on = btn.dataset.tab === next;
    btn.classList.toggle("is-on", on);
    btn.setAttribute("aria-selected", String(on));
  });
  ["home", "journal", "charms", "circle"].forEach((name) => {
    document.getElementById(`view-${name}`).classList.toggle("is-on", name === next);
  });
  els.kicker.textContent = `${kickers[next]}  ·  ${monthName()} ${now().getFullYear()}`;
  render();
}

function render() {
  els.settingsOpen.innerHTML = markSvg("currentColor");
  els.preview.classList.toggle("is-on", state.previewFirst);
  if (tab === "home") renderHome();
  if (tab === "journal") renderJournal();
  if (tab === "charms") renderCharms();
  if (tab === "circle") renderCircle();
}

function renderHome() {
  const checks = todayChecks();
  const total = state.habits.length;
  const done = state.habits.filter((habit) => checks.has(habit.id)).length;
  const progress = total ? done / total : 0;
  const first = isFirstMorning() && !ritualDone();
  const bunny = currentBunny();
  const note = state.journal[dayKey()];

  els.home.innerHTML = `
    <section class="hero">
      <div class="hero-ring" style="--progress:${progress}">
        <svg class="ring" viewBox="0 0 100 100">
          <circle class="track" cx="50" cy="50" r="46" pathLength="1"/>
          <circle class="value" cx="50" cy="50" r="46" pathLength="1"/>
        </svg>
        <button class="hero-mark ${first ? "is-pulse" : ""}" data-act="hero" aria-label="${first ? `Welcome ${monthName()}` : "White Rabbits"}">
          ${markSvg("currentColor")}
        </button>
      </div>
      <h1 class="wordmark">White Rabbits</h1>
      <p class="greeting">${sanctuaryGreeting(first)}</p>
      <p class="metric">${total ? (done === 0 ? (firstName() ? `${escapeHtml(firstName())}, a gentle beginning` : "A gentle beginning") : done === total ? (firstName() ? `${escapeHtml(firstName())}, today is complete` : "Today is complete") : `${done} kept today`) : "Add a habit to begin"}</p>
    </section>

    ${first ? `
      <article class="welcome-card">
        <p class="kicker">The first of ${monthName()}</p>
        <div class="welcome-stamp">${charmSvg(bunny, true)}</div>
        <strong>${bunny.name}</strong>
        <p class="greeting">${firstName() ? `${escapeHtml(firstName())}, this month’s charm is here. No hurry.` : "This month’s charm is here. No hurry."}</p>
        <button class="ghost" data-act="ritual">Begin the month</button>
      </article>
    ` : ""}

    ${stampCardHtml()}

    ${circlePeekHtml()}

    ${currentMonth()?.intention ? `
      <article class="manifesto-card">
        <p class="kicker">${monthName()} intention</p>
        <h2>${escapeHtml(currentMonth().intention)}</h2>
        <button class="ghost" data-share="${now().getMonth() + 1}">Share story card</button>
      </article>
    ` : ""}

    ${inspireHtml()}

    <div class="section-head">
      <h2>Today</h2>
      <button class="link" data-act="habits">Edit</button>
    </div>
    ${state.habits.length ? state.habits.map((habit) => {
      const on = checks.has(habit.id);
      const dots = weekDots(habit.id);
      return `
        <button class="habit ${on ? "is-on" : ""}" data-habit="${habit.id}">
          <span class="check"></span>
          <span>
            <b>${escapeHtml(habit.name)}</b>
            <small>${growthCopy(habit.id, on)}</small>
          </span>
          <span class="dots" aria-hidden="true">${dots.map((dot) => `<i class="${dot ? "on" : ""}"></i>`).join("")}</span>
        </button>
      `;
    }).join("") : `<p class="lede">${firstName() ? `${escapeHtml(firstName())}, these quiet promises are yours to keep.` : "Keep four quiet promises. Nothing more."}</p>`}

    <div class="section-head">
      <h2>Journal</h2>
    </div>
    ${journalInviteHtml(note)}
  `;
}

function renderJournal() {
  const today = dayKey();
  const note = state.journal[today];
  const current = now();
  const month = current.getMonth() + 1;
  const year = current.getFullYear();
  const thisMonth = monthPages(month, year).filter(([key]) => key !== today).reverse();
  const archive = lastMonthArchive();
  const handoff = inHandoff() && hasArchive(archive);
  const earlier = journalMonthGroups().filter((group) => {
    if (group.prefix === monthKey(current)) return false;
    if (handoff && group.prefix === yearMonthKey(archive.month, archive.year)) return false;
    return true;
  });

  els.journal.innerHTML = `
    ${journalInviteHtml(note)}

    ${handoff ? `
      <button class="month-close" type="button" data-month-log="${yearMonthKey(archive.month, archive.year)}">
        <span class="welcome-stamp">${charmSvg(archive.bunny, Boolean(archive.ritual?.completed))}</span>
        <p class="kicker">${archive.label} ${archive.year}</p>
        <strong>${archive.label} is kept</strong>
        <p>${archive.ritual?.intention ? escapeHtml(archive.ritual.intention) : "Your pages live with this stamp. Look back whenever you like."}</p>
      </button>
    ` : ""}

    <div class="section-head">
      <h2>${monthName()}</h2>
    </div>
    ${monthCalendarHtml(month, year)}
    ${thisMonth.length ? thisMonth.map(([key, entry]) => noteCardHtml(key, entry)).join("") : (pageHasContent(note) ? "" : `<p class="lede">${firstName() ? `${escapeHtml(firstName())}, this month will gather here, one page at a time.` : "This month will gather here, one page at a time."}</p>`)}

    ${earlier.length ? `
      <div class="section-head">
        <h2>Earlier</h2>
      </div>
      ${earlier.map((group) => `
        <button class="month-row" type="button" data-month-log="${group.prefix}">
          <span>
            <strong>${group.label} ${group.year}</strong>
            <small>${group.ritual?.intention ? escapeHtml(group.ritual.intention) : "Pages kept, quietly"}</small>
          </span>
          <span class="month-row-mark">${charmSvg(group.bunny, Boolean(state.months[group.prefix]?.completed))}</span>
        </button>
      `).join("")}
    ` : ""}
  `;
}

function renderCharms() {
  const unlocked = unlockedIds();
  const count = unlocked.size;
  els.charms.innerHTML = `
    <p class="lede">${firstName() ? `${escapeHtml(firstName())}, these charms wait for the first of each month.` : "Seasonal charms, collected when you open the first of the month."}</p>
    <div class="charm-progress">
      <strong>${count} of 12</strong>
      <span class="kicker">${count === 12 ? "A complete year" : "Still gathering"}</span>
    </div>
    <div class="charm-grid">
      ${BUNNIES.map((bunny) => {
        const open = unlocked.has(bunny.id);
        return `
          <button class="charm ${open ? "is-open" : "is-locked"}" data-charm="${bunny.id}" aria-label="${bunny.name}, ${bunny.season}${open ? ", collected" : ", locked"}">
            ${charmSvg(bunny, open)}
          </button>
        `;
      }).join("")}
    </div>
  `;
}

function circlePeekHtml() {
  const circle = circleState();
  if (!circle.joined) return "";
  const fellows = fellowCards(now()).slice(0, 3);
  const mine = publicCard();
  return `
    <button class="circle-peek" type="button" data-tab="circle">
      <div class="peek-stamps" aria-hidden="true">
        ${fellows.map((card) => `<span>${charmSvg(bunnyByMonth(card.month), true)}</span>`).join("")}
      </div>
      <p class="kicker">Shared Sanctuary</p>
      <strong>${mine ? "Your intention is in the circle" : "A quiet circle is gathering"}</strong>
      <p>Intentions and stamps only. Send a spark if you like.</p>
    </button>
  `;
}

function sanctuaryCardHtml(card, options = {}) {
  const bunny = BUNNIES.find((item) => item.id === card.charmId) || bunnyByMonth(card.month);
  const sent = hasSparked(card.id);
  const you = card.kind === "you";
  const friend = card.kind === "friend";
  return `
    <article class="sanctuary-card ${you ? "is-yours" : ""}">
      <div class="sanctuary-stamp">${charmSvg(bunny, true)}</div>
      <p class="kicker">${bunny.season}  ·  ${bunny.name}</p>
      <p class="sanctuary-name">${escapeHtml(card.name)}</p>
      <h3 class="sanctuary-intention">${escapeHtml(card.intention)}</h3>
      ${you ? `<p class="sanctuary-note">This is all the circle can see.</p>` : `
        <button class="spark-btn ${sent ? "is-sent" : ""}" type="button" data-spark="${escapeHtml(card.id)}" ${sent ? "disabled" : ""}>
          ${sparkSvg()}
          ${sent ? "Spark sent" : "Send a spark"}
        </button>
      `}
      ${friend && options.release ? `<button class="quiet" type="button" data-release="${escapeHtml(card.id)}">Release this card</button>` : ""}
    </article>
  `;
}

function renderCircle() {
  const circle = circleState();
  if (!circle.joined) {
    els.circle.innerHTML = `
      <section class="circle-gate">
        <div class="mark">${markSvg("currentColor")}</div>
        <p class="kicker">Opt in, whenever you like</p>
        <h2>Shared Sanctuary</h2>
        <p class="lede">${firstName() ? `${escapeHtml(firstName())}, a gentle circle for monthly resets. No scores, no streaks, no comparison.` : "A gentle circle for monthly resets. No scores, no streaks, no comparison."}</p>
        <ul class="privacy-list">
          <li><strong>Shared, if you join</strong>Your name, this month’s intention, and your seasonal stamp.</li>
          <li><strong>Never shared</strong>Journal notes, photographs, voice transcripts, and habits stay on this phone.</li>
        </ul>
        <p class="lede">The circle lives on this device for now. Fellow intentions gather here as a quiet, local circle. Invite a real friend by exchanging sanctuary cards. Nothing is uploaded.</p>
        <button class="primary" type="button" data-act="join-circle">Enter the circle</button>
        <button class="ghost" type="button" data-act="home">Keep this sanctuary private</button>
      </section>
    `;
    return;
  }

  maybeArriveSpark();
  const mine = publicCard();
  const friends = circle.friends;
  const fellows = fellowCards(now());
  const mail = unseenSparks()[0];
  const landed = circle.sparksReceived.some((item) => item.monthKey === monthKey());

  els.circle.innerHTML = `
    <p class="lede">${firstName() ? `${escapeHtml(firstName())}, this is inspiration only. Cheer a reset. Never weigh it.` : "Inspiration only. Cheer a reset. Never weigh it."}</p>

    ${mail ? `
      <article class="spark-mail">
        <p class="kicker">A quiet cheer</p>
        <p>${escapeHtml(mail.name)} sent a spark for your month. No reply needed.</p>
        <button class="ghost" type="button" data-act="seen-spark">Keep it</button>
      </article>
    ` : ""}

    <div class="section-head">
      <h2>Your public card</h2>
      ${mine ? `<button class="link" type="button" data-act="invite-circle">Invite</button>` : ""}
    </div>
    ${mine ? `
      ${sanctuaryCardHtml(mine)}
      ${landed ? `<p class="sanctuary-landed">Sparks have landed. No tally, only warmth.</p>` : ""}
    ` : `
      <article class="sanctuary-card is-waiting">
        <p class="kicker">${monthName()}</p>
        <h3 class="sanctuary-intention">Your intention is still private</h3>
        <p class="sanctuary-note">Set it when you are ready. The circle can wait. Your journal is never asked for.</p>
        <button class="primary" type="button" data-act="intention">Set this month’s intention</button>
      </article>
    `}

    <div class="section-head">
      <h2>Friends</h2>
      <button class="link" type="button" data-act="add-friend">Add</button>
    </div>
    ${friends.length ? friends.map((card) => sanctuaryCardHtml({ ...card, kind: "friend" }, { release: true })).join("") : `
      <p class="lede">Invite someone with a sanctuary card. You will see their intention and stamp, nothing else.</p>
    `}

    <div class="section-head">
      <h2>Fellow intentions</h2>
    </div>
    ${fellows.map((card) => sanctuaryCardHtml(card)).join("")}

    <button class="quiet" type="button" data-act="leave-circle">Step out of the circle</button>
  `;
}

function joinCircle() {
  const circle = circleState();
  circle.joined = true;
  circle.seenIntro = true;
  save();
  haptic([10, 24, 14]);
  render();
}

function leaveCircle() {
  const circle = circleState();
  circle.joined = false;
  save();
  haptic(8);
  render();
}

function toggleCircle() {
  const circle = circleState();
  if (circle.joined) {
    leaveCircle();
    openSettings();
    return;
  }
  if (circle.seenIntro) {
    joinCircle();
    openSettings();
    return;
  }
  closeOverlay(els.sheet);
  setTab("circle");
}

function markSparksSeen() {
  const key = monthKey();
  circleState().sparksReceived.forEach((item) => {
    if (item.monthKey === key) item.seen = true;
  });
  save();
  haptic(8);
  render();
}

function sendSpark(id) {
  if (!id || hasSparked(id)) return;
  const circle = circleState();
  circle.sparksGiven[sparkKey(id)] = new Date().toISOString();
  save();
  haptic([10, 30, 14, 40, 18]);
  sparkChime();
  const btn = document.querySelector(`[data-spark="${CSS.escape(id)}"]`);
  sparkDust(btn);
  if (btn) {
    btn.classList.add("is-sent");
    btn.disabled = true;
    btn.innerHTML = `${sparkSvg()} Spark sent`;
  }
}

function sparkDust(button) {
  const card = button?.closest(".sanctuary-card");
  if (!card || reduced) return;
  for (let i = 0; i < 8; i += 1) {
    const spec = document.createElement("i");
    spec.className = "spark-mote";
    spec.style.left = `${20 + Math.random() * 60}%`;
    spec.style.bottom = `${18 + Math.random() * 24}%`;
    spec.style.animationDelay = `${Math.random() * 0.2}s`;
    card.appendChild(spec);
    spec.addEventListener("animationend", () => spec.remove());
  }
}

function openInvite() {
  const card = publicCard();
  if (!card) {
    openIntention();
    return;
  }
  const token = encodeCard(card);
  openOverlay(els.sheet, `
    <section class="sheet" role="dialog" aria-labelledby="invite-title">
      <div class="handle"></div>
      <p class="kicker">Sanctuary card</p>
      <h2 id="invite-title">Invite a friend</h2>
      <p class="lede">This token holds only your name, stamp, and monthly intention. Journal pages stay here.</p>
      <label class="field token-field">
        <textarea id="invite-token" readonly rows="4">${escapeHtml(token)}</textarea>
      </label>
      <button class="primary" type="button" id="copy-token">Copy sanctuary card</button>
      <button class="ghost" type="button" id="share-token">Share</button>
      <button class="ghost" type="button" data-act="close-sheet">Close</button>
    </section>
  `);
  document.getElementById("copy-token").addEventListener("click", async () => {
    try {
      await navigator.clipboard.writeText(token);
      haptic(10);
      document.getElementById("copy-token").textContent = "Copied";
    } catch {
      document.getElementById("invite-token").select();
    }
  });
  document.getElementById("share-token").addEventListener("click", async () => {
    const text = `${card.name} · ${card.intention}\n\nA White Rabbits sanctuary card. Intention and stamp only.\n${token}`;
    try {
      if (navigator.share) {
        await navigator.share({ title: "White Rabbits sanctuary card", text });
        return;
      }
    } catch { /* cancelled */ }
    try { await navigator.clipboard.writeText(text); haptic(10); } catch { /* ignore */ }
  });
}

function openAddFriend() {
  openOverlay(els.sheet, `
    <section class="sheet" role="dialog" aria-labelledby="friend-title">
      <div class="handle"></div>
      <p class="kicker">A friend’s card</p>
      <h2 id="friend-title">Add to your circle</h2>
      <p class="lede">Paste their sanctuary token. You will see their intention and seasonal stamp, never their journal.</p>
      <label class="field">
        <textarea id="friend-token" rows="4" maxlength="800" placeholder="WR1."></textarea>
      </label>
      <button class="primary" type="button" id="save-friend">Keep this card</button>
      <button class="ghost" type="button" data-act="close-sheet">Close</button>
    </section>
  `);
  document.getElementById("save-friend").addEventListener("click", () => {
    const card = decodeCard(document.getElementById("friend-token").value);
    if (!card) {
      document.getElementById("friend-token").focus();
      return;
    }
    const circle = circleState();
    if (card.id === circle.id) {
      closeOverlay(els.sheet);
      return;
    }
    circle.friends = [card, ...circle.friends.filter((item) => item.id !== card.id)];
    save();
    haptic([10, 24, 14]);
    closeOverlay(els.sheet);
    render();
  });
}

function releaseFriend(id) {
  const circle = circleState();
  circle.friends = circle.friends.filter((item) => item.id !== id);
  save();
  haptic(8);
  render();
}

function openOverlay(node, html) {
  node.hidden = false;
  node.classList.add("is-on");
  node.innerHTML = html;
}

function closeOverlay(node) {
  stopListening();
  node.classList.remove("is-on");
  node.hidden = true;
  node.innerHTML = "";
}

function openRitual() {
  haptic(8);
  const bunny = currentBunny();
  const n = firstName();
  const archive = lastMonthArchive();
  const kept = hasArchive(archive);
  openOverlay(els.ritual, `
    <section class="ritual month-welcome">
      <p class="kicker">The first of ${monthName()}</p>
      <div class="charm-hero">${charmSvg(bunny, true)}</div>
      <h2 class="welcome-title">${n ? `Welcome, ${escapeHtml(n)}.` : "Welcome."}</h2>
      <p class="lede">${kept ? `${archive.label} is kept. ${monthName()} has arrived.` : bunny.line} Say White Rabbits when you like, and ${bunny.name} is yours.</p>
      <button class="primary" id="say-welcome" type="button">Say White Rabbits</button>
      <p class="say-hint">${canListen() ? "Or speak the words, softly. There is no timer." : "There is no timer. Begin whenever you like."}</p>
      <button class="skip" type="button" data-act="close-ritual">I’ll begin later</button>
    </section>
  `);

  let heard = false;
  const succeed = () => {
    if (heard) return;
    heard = true;
    stopListening();
    ensureAudio();
    haptic([18, 40, 24, 50, 40, 80, 60]);
    chime();
    collectCharm();
    celebrate();
  };

  document.getElementById("say-welcome")?.addEventListener("click", succeed);
  if (canListen()) startListening(succeed);
}

function collectCharm() {
  const date = now();
  const key = monthKey(date);
  const bunny = currentBunny(date);
  state.months[key] = {
    ...state.months[key],
    key,
    year: date.getFullYear(),
    label: monthName(date),
    completed: true,
    charmId: bunny.id,
    saidAt: state.months[key]?.saidAt || new Date().toISOString(),
  };
  save();
}

function celebrate() {
  const bunny = currentBunny();
  const archive = lastMonthArchive();
  const kept = hasArchive(archive);
  openOverlay(els.ritual, `
    <section class="celebrate">
      <div class="dust" id="dust"></div>
      <div class="charm-hero">${charmSvg(bunny, true)}</div>
      <p class="kicker">${bunny.season}</p>
      <h2>${firstName() ? `${monthName()} is yours, ${escapeHtml(firstName())}.` : `${monthName()} is yours.`}</h2>
      <p>${kept ? `${archive.label} stays in your journal. ${bunny.name} is this month’s stamp.` : `${bunny.name} is this month’s stamp. A little luck for the days ahead.`}</p>
      <button class="primary" data-act="after-ritual">Set this month’s intention</button>
    </section>
  `);
  if (!reduced) sprinkle();
}

function sprinkle() {
  const dust = document.getElementById("dust");
  if (!dust) return;
  for (let i = 0; i < 16; i += 1) {
    const spec = document.createElement("i");
    spec.style.left = `${12 + Math.random() * 76}%`;
    spec.style.bottom = `${10 + Math.random() * 30}%`;
    spec.style.animationDelay = `${Math.random() * 0.5}s`;
    spec.style.width = spec.style.height = `${4 + Math.random() * 5}px`;
    dust.appendChild(spec);
  }
}

function openIntention() {
  const ritual = currentMonth() ?? {};
  const today = state.journal[dayKey()] ?? {};
  const archive = lastMonthArchive();
  const kept = hasArchive(archive);
  let photo = ritual.photo || today.photo || "";
  closeOverlay(els.ritual);
  openOverlay(els.sheet, `
    <section class="sheet" role="dialog" aria-labelledby="intention-title">
      <div class="handle"></div>
      <p class="kicker">${monthName()} ${now().getFullYear()}</p>
      <h2 id="intention-title">This month’s intention</h2>
      <p class="lede">${firstName() ? `${escapeHtml(firstName())}, one true sentence for ${monthName()}.` : `One true sentence for ${monthName()}.`} ${kept ? `${archive.label} remains yours to look back on.` : "It becomes the title of your story."}</p>
      <button class="photo-btn ${photo ? "has-photo" : ""}" id="photo-btn" type="button">
        ${photo ? `<img src="${photo}" alt="Photograph for this month">` : `<span class="photo-empty">Add a photograph<small>The light that will hold your intention</small></span>`}
      </button>
      <input class="visually-hidden" id="photo-input" type="file" accept="image/*" />
      <label class="field">
        <textarea id="intention-input" maxlength="80" rows="2" placeholder="What is your focus?">${escapeHtml(ritual.intention ?? "")}</textarea>
        <span id="count">${(ritual.intention ?? "").length}/80</span>
      </label>
      <div class="chips">
        ${INTENTIONS.map((item) => `<button class="chip" type="button" data-suggest="${escapeHtml(item)}">${item}</button>`).join("")}
      </div>
      <button class="primary" id="save-intention" type="button">Make my story card</button>
      <button class="ghost" data-act="close-sheet" type="button">Close</button>
    </section>
  `);

  const input = document.getElementById("intention-input");
  const count = document.getElementById("count");
  const photoInput = document.getElementById("photo-input");
  input.addEventListener("input", () => { count.textContent = `${input.value.length}/80`; });
  document.getElementById("photo-btn").addEventListener("click", () => photoInput.click());
  photoInput.addEventListener("change", async (event) => {
    const file = event.target.files?.[0];
    if (!file) return;
    photo = await compressImage(file);
    const btn = document.getElementById("photo-btn");
    btn.classList.add("has-photo");
    btn.innerHTML = `<img src="${photo}" alt="Photograph for this month">`;
  });
  els.sheet.querySelectorAll("[data-suggest]").forEach((chip) => {
    chip.addEventListener("click", () => {
      input.value = chip.dataset.suggest;
      count.textContent = `${input.value.length}/80`;
      haptic(8);
    });
  });
  document.getElementById("save-intention").addEventListener("click", async () => {
    const intention = input.value.trim();
    if (!intention) { input.focus(); return; }
    const date = now();
    const key = monthKey(date);
    const bunny = currentBunny(date);
    const light = todayInspiration(date);
    state.months[key] = {
      ...state.months[key],
      key,
      year: date.getFullYear(),
      label: monthName(date),
      completed: true,
      charmId: bunny.id,
      saidAt: state.months[key]?.saidAt || new Date().toISOString(),
      intention,
      photo,
      quote: light.line,
    };
    if (photo) {
      const day = state.journal[dayKey()] ?? {};
      state.journal[dayKey()] = { ...day, photo, updated: new Date().toISOString() };
    }
    save();
    haptic([12, 28, 16]);
    await openStoryPreview(date.getMonth() + 1);
  });
}

function cssToken(name) {
  return getComputedStyle(document.documentElement).getPropertyValue(name).trim();
}

async function svgImage(markup) {
  const svg = markup.includes("xmlns") ? markup : markup.replace("<svg", '<svg xmlns="http://www.w3.org/2000/svg"');
  const url = URL.createObjectURL(new Blob([svg], { type: "image/svg+xml" }));
  const image = new Image();
  image.src = url;
  await image.decode();
  URL.revokeObjectURL(url);
  return image;
}

function wrapCanvasText(ctx, text, x, y, max, leading, maxLines = 4) {
  const words = String(text).split(" ");
  const lines = [];
  let line = "";
  words.forEach((word) => {
    const test = `${line}${word} `;
    if (ctx.measureText(test).width > max && line) {
      lines.push(line.trim());
      line = `${word} `;
    } else line = test;
  });
  lines.push(line.trim());
  lines.slice(0, maxLines).forEach((row, i) => ctx.fillText(row, x, y + i * leading));
  return Math.min(lines.length, maxLines);
}

async function drawStory(month) {
  const slot = stampState(month);
  const ritual = slot.ritual ?? {};
  const intention = ritual.intention || "Begin again, beautifully.";
  const quote = ritual.quote || todayInspiration(now()).line;
  const photoSrc = ritual.photo || slot.pages.find(([, entry]) => entry.photo)?.[1].photo || "";
  const bunny = slot.bunny;
  const bg = cssToken("--bg") || "#f6f1ea";
  const ink = cssToken("--ink") || "#2a2622";
  const muted = cssToken("--muted") || "#7a736b";
  const accent = cssToken("--accent") || "#c4a36a";

  const canvas = document.createElement("canvas");
  canvas.width = 1080;
  canvas.height = 1920;
  const ctx = canvas.getContext("2d");

  const sky = ctx.createLinearGradient(0, 0, 0, 1920);
  sky.addColorStop(0, bg);
  sky.addColorStop(1, accent + "33");
  ctx.fillStyle = sky;
  ctx.fillRect(0, 0, 1080, 1920);

  ctx.strokeStyle = accent;
  ctx.globalAlpha = 0.55;
  ctx.lineWidth = 2;
  ctx.strokeRect(56, 56, 968, 1808);
  ctx.globalAlpha = 1;

  ctx.fillStyle = accent;
  ctx.font = "500 22px -apple-system, 'SF Pro Display', sans-serif";
  ctx.letterSpacing = "10px";
  ctx.fillText("WHITE RABBITS", 96, 130);
  ctx.fillStyle = muted;
  ctx.font = "500 20px -apple-system, 'SF Pro Display', sans-serif";
  ctx.letterSpacing = "6px";
  ctx.fillText(`${slot.bunny.season.toUpperCase()}  ${slot.year}`, 96, 168);

  let textTop = 760;
  if (photoSrc) {
    const photo = new Image();
    photo.src = photoSrc;
    await photo.decode();
    const x = 96;
    const y = 210;
    const w = 888;
    const h = 720;
    ctx.save();
    ctx.beginPath();
    ctx.roundRect(x, y, w, h, 28);
    ctx.clip();
    const srcRatio = photo.width / photo.height;
    const dstRatio = w / h;
    let sx = 0; let sy = 0; let sw = photo.width; let sh = photo.height;
    if (srcRatio > dstRatio) {
      sw = photo.height * dstRatio;
      sx = (photo.width - sw) / 2;
    } else {
      sh = photo.width / dstRatio;
      sy = (photo.height - sh) / 2;
    }
    ctx.drawImage(photo, sx, sy, sw, sh, x, y, w, h);
    ctx.restore();
    const veil = ctx.createLinearGradient(0, 760, 0, 930);
    veil.addColorStop(0, "rgba(246,241,234,0)");
    veil.addColorStop(1, bg);
    ctx.fillStyle = veil;
    ctx.fillRect(96, 760, 888, 170);
    textTop = 1000;
  }

  const stamp = await svgImage(charmSvg(bunny, true));
  const stampY = photoSrc ? 820 : 240;
  const stampX = photoSrc ? 430 : 390;
  const stampSize = photoSrc ? 220 : 300;
  ctx.beginPath();
  ctx.arc(stampX + stampSize / 2, stampY + stampSize / 2, stampSize / 2 + 8, 0, Math.PI * 2);
  ctx.fillStyle = bg;
  ctx.fill();
  ctx.strokeStyle = accent;
  ctx.lineWidth = 3;
  ctx.stroke();
  ctx.drawImage(stamp, stampX, stampY, stampSize, stampSize);
  if (!photoSrc) textTop = 600;

  ctx.fillStyle = muted;
  ctx.font = "500 20px -apple-system, 'SF Pro Display', sans-serif";
  ctx.letterSpacing = "7px";
  ctx.fillText("THIS MONTH I INTEND", 96, textTop);

  ctx.fillStyle = ink;
  ctx.letterSpacing = "-2px";
  ctx.font = "300 78px -apple-system, 'SF Pro Display', sans-serif";
  const lines = wrapCanvasText(ctx, intention, 96, textTop + 88, 888, 88, 3);

  ctx.fillStyle = muted;
  ctx.letterSpacing = "0px";
  ctx.font = "400 28px -apple-system, 'SF Pro Display', sans-serif";
  wrapCanvasText(ctx, quote, 96, textTop + 88 + lines * 88 + 48, 888, 40, 3);

  ctx.fillStyle = accent;
  ctx.font = "500 20px -apple-system, 'SF Pro Display', sans-serif";
  ctx.letterSpacing = "4px";
  ctx.fillText("PAUSE   ·   REFLECT   ·   INTEND   ·   BEGIN", 96, 1848);

  return canvas;
}

async function openStoryPreview(month) {
  const canvas = await drawStory(month);
  const url = canvas.toDataURL("image/png");
  openOverlay(els.sheet, `
    <section class="sheet story-sheet" role="dialog" aria-labelledby="story-title">
      <div class="handle"></div>
      <p class="kicker">Instagram  ·  TikTok</p>
      <h2 id="story-title">Your story card</h2>
      <p class="lede">${hasArchive() ? `${monthName()} begins here. Last month’s pages stay in your journal.` : "Your intention is the title of the month. Keep it private, or send it into the world."}</p>
      <img class="story-frame" src="${url}" alt="Story card preview">
      <button class="primary" id="share-card" type="button">Share story card</button>
      <button class="ghost" data-act="close-sheet" type="button">Close</button>
    </section>
  `);
  document.getElementById("share-card").addEventListener("click", () => shareStory(month, canvas));
}

async function shareStory(month = now().getMonth() + 1, readyCanvas = null) {
  const slot = stampState(Number(month));
  if (!slot.ritual?.intention) {
    openIntention();
    return;
  }
  haptic(10);
  const canvas = readyCanvas || await drawStory(Number(month));
  const blob = await new Promise((resolve) => canvas.toBlob(resolve, "image/png"));
  if (!blob) return;
  const file = new File([blob], `white-rabbits-${slot.year}-${String(month).padStart(2, "0")}.png`, { type: "image/png" });
  try {
    if (navigator.canShare?.({ files: [file] })) {
      await navigator.share({
        files: [file],
        title: slot.ritual.intention,
        text: `${slot.ritual.intention}  ·  ${slot.bunny.season} ${slot.year}  #WhiteRabbits`,
      });
      return;
    }
  } catch { /* user cancelled */ }
  const link = document.createElement("a");
  link.href = URL.createObjectURL(blob);
  link.download = file.name;
  link.click();
  URL.revokeObjectURL(link.href);
}

function openCompose(key = dayKey()) {
  const entry = state.journal[key] ?? {};
  let mood = entry.mood ?? "";
  let photo = entry.photo ?? "";
  const today = key === dayKey();
  openOverlay(els.sheet, `
    <section class="sheet" role="dialog" aria-labelledby="journal-title">
      <div class="handle"></div>
      <p class="kicker">${dayLabel(key)}</p>
      <h2 id="journal-title">${today ? "Today’s page" : "A kept page"}</h2>
      <p class="lede">${firstName() ? `${escapeHtml(firstName())}, this page stays on this phone, in your journal.` : "This page stays on this phone, in your journal."}</p>
      <button class="photo-btn ${photo ? "has-photo" : ""}" id="photo-btn" type="button">
        ${photo ? `<img src="${photo}" alt="">` : `<span class="photo-empty">Add a photograph</span>`}
      </button>
      <input class="visually-hidden" id="photo-input" type="file" accept="image/*" />
      <label class="field">
        <textarea class="rich" id="journal-text" maxlength="2000" placeholder="A few honest lines, whenever you like...">${escapeHtml(entry.text ?? "")}</textarea>
        <span id="count">${(entry.text ?? "").length}/2000</span>
      </label>
      ${canListen() ? `
        <button class="ghost voice-btn" id="compose-voice" type="button" style="width:auto;margin:0 0 12px;min-height:44px;padding:0 14px;display:inline-flex;gap:8px">
          <svg viewBox="0 0 18 18" fill="none" stroke="currentColor" stroke-width="1.5"><rect x="6.2" y="2.4" width="5.6" height="8.4" rx="2.8"/><path d="M4.4 8.8a4.6 4.6 0 009.2 0M9 13.4V16"/></svg>
          Voice to text
        </button>
      ` : ""}
      <div class="chips" id="moods">
        ${MOODS.map((item) => `<button class="chip ${mood === item ? "is-on" : ""}" type="button" data-mood="${item}">${item}</button>`).join("")}
      </div>
      <button class="primary" id="save-journal" type="button">Keep this page</button>
      <button class="ghost" id="close-compose" type="button">Close</button>
    </section>
  `);

  const input = document.getElementById("journal-text");
  const count = document.getElementById("count");
  const photoInput = document.getElementById("photo-input");
  input.addEventListener("input", () => { count.textContent = `${input.value.length}/2000`; });
  document.getElementById("photo-btn").addEventListener("click", () => photoInput.click());
  const composeVoice = document.getElementById("compose-voice");
  composeVoice?.addEventListener("click", () => {
    if (!canListen()) return;
    const on = composeVoice.classList.toggle("is-on");
    if (!on) { stopListening(); return; }
    haptic(8);
    const prefix = input.value.trim();
    startDictation((text) => {
      input.value = prefix ? `${prefix} ${text}` : text;
      count.textContent = `${input.value.length}/2000`;
    });
  });
  photoInput.addEventListener("change", async (event) => {
    const file = event.target.files?.[0];
    if (!file) return;
    photo = await compressImage(file);
    const btn = document.getElementById("photo-btn");
    btn.classList.add("has-photo");
    btn.innerHTML = `<img src="${photo}" alt="">`;
  });
  els.sheet.querySelectorAll("[data-mood]").forEach((chip) => {
    chip.addEventListener("click", () => {
      mood = mood === chip.dataset.mood ? "" : chip.dataset.mood;
      els.sheet.querySelectorAll("[data-mood]").forEach((el) => el.classList.toggle("is-on", el.dataset.mood === mood));
      haptic(8);
    });
  });
  const keepDraft = (andShow) => {
    persistPage(key, { text: input.value, mood, photo });
    haptic([10, 24, 14]);
    if (andShow) showJournal();
    else {
      closeOverlay(els.sheet);
      render();
    }
  };
  document.getElementById("save-journal").addEventListener("click", () => keepDraft(true));
  document.getElementById("close-compose").addEventListener("click", () => keepDraft(pageHasContent({ text: input.value, mood, photo })));
}

function openHabits() {
  openOverlay(els.sheet, `
    <section class="sheet" role="dialog" aria-labelledby="habits-title">
      <div class="handle"></div>
      <p class="kicker">Quiet promises</p>
      <h2 id="habits-title">Habits</h2>
      <p class="lede">${firstName() ? `${escapeHtml(firstName())}, four is plenty. Keep them small enough to keep.` : "Four is plenty. Keep them small enough to keep."}</p>
      ${state.habits.map((habit) => `
        <div class="setting">
          <strong>${escapeHtml(habit.name)}</strong>
          <button class="quiet" data-remove="${habit.id}">Remove</button>
        </div>
      `).join("")}
      <label class="field">
        <input id="habit-name" maxlength="32" placeholder="Add a habit" />
      </label>
      <button class="primary" id="add-habit" type="button">Add</button>
      <button class="ghost" data-act="close-sheet" type="button">Done</button>
    </section>
  `);
  document.getElementById("add-habit").addEventListener("click", () => {
    const name = document.getElementById("habit-name").value.trim();
    if (!name || state.habits.length >= 6) return;
    state.habits.push({ id: `h-${Date.now()}`, name });
    save();
    haptic(10);
    openHabits();
    render();
  });
}

function openCharm(id) {
  openStamp(BUNNIES.find((b) => b.id === id)?.month ?? now().getMonth() + 1);
}

function saidLabel(iso) {
  if (!iso) return "";
  const date = new Date(iso);
  return `Said at ${new Intl.DateTimeFormat("en-GB", { hour: "2-digit", minute: "2-digit", day: "numeric", month: "long" }).format(date)}`;
}

function openMonthLog(prefix) {
  const [year, month] = String(prefix).split("-").map(Number);
  if (!month || !year) return;
  const bunny = bunnyByMonth(month);
  const pages = monthPages(month, year).slice().reverse();
  const ritual = state.months[prefix];
  haptic(8);
  openOverlay(els.sheet, `
    <section class="sheet" role="dialog" aria-labelledby="month-log-title">
      <div class="handle"></div>
      <p class="kicker">${bunny.season} ${year}</p>
      <h2 id="month-log-title">${ritual?.intention ? escapeHtml(ritual.intention) : bunny.name}</h2>
      <p class="lede">${firstName() ? `${escapeHtml(firstName())}, these pages stay here. Nothing is scored.` : "These pages stay here. Nothing is scored."}</p>
      ${monthCalendarHtml(month, year)}
      ${pages.length ? pages.map(([key, entry]) => noteCardHtml(key, entry)).join("") : `<p class="lede">No pages for ${bunny.season} yet.</p>`}
      ${ritual?.intention ? `<button class="primary" data-share="${month}" type="button">Share story card</button>` : ""}
      <button class="ghost" data-stamp="${prefix}" type="button">Open the stamp</button>
    </section>
  `);
}

function openStamp(ref) {
  const raw = String(ref);
  let month;
  let year;
  if (raw.includes("-")) {
    [year, month] = raw.split("-").map(Number);
  } else {
    month = Number(raw);
    year = now().getFullYear();
  }
  const slot = stampState(month, year);
  const { bunny, ritual, pages, collected, current, upcoming } = slot;
  const vision = pages.find(([, entry]) => entry.photo)?.[1].photo;
  const pageList = pages.length ? `
        <div class="memory-list">
          ${pages.slice().reverse().map(([key, entry]) => noteCardHtml(key, entry)).join("")}
        </div>
      ` : "";
  let body;
  if (collected) {
    body = `
      <p class="lede">${bunny.line}</p>
      ${ritual?.intention ? `<p class="manifesto">${escapeHtml(ritual.intention)}</p>` : ""}
      ${ritual?.saidAt ? `<p class="kicker">${saidLabel(ritual.saidAt)}</p>` : `<p class="kicker">The first of ${bunny.season}</p>`}
      ${(ritual?.photo || vision) ? `<img class="memory-photo" src="${ritual?.photo || vision}" alt="Vision for ${bunny.season}">` : ""}
      ${pageList || `<p class="lede">${firstName() ? `${escapeHtml(firstName())}, your ${bunny.season} pages will live here.` : "No journal pages for this month yet."}</p>`}
      ${ritual?.intention ? `<button class="primary" data-share="${month}" type="button">Share story card</button>` : `<button class="primary" data-act="intention" type="button">Set this month’s intention</button>`}
      <button class="ghost" data-act="compose" type="button">Write into ${bunny.season}</button>
    `;
  } else if (upcoming) {
    body = `
      <p class="lede">${firstName() ? `${escapeHtml(firstName())}, ${bunny.name} waits for the first of ${bunny.season}. There is no hurry.` : `${bunny.name} waits for the first of ${bunny.season}. The stamp stays empty until then.`}</p>
      <button class="primary" data-act="close-sheet" type="button">Close</button>
    `;
  } else if (current) {
    body = `
      <p class="lede">${firstName() ? `${escapeHtml(firstName())}, say White Rabbits on the first of ${bunny.season} to stamp the month. There is no hurry.` : `Say White Rabbits on the first of ${bunny.season} to stamp the month. There is no hurry.`}</p>
      ${pageList}
      <button class="primary" data-act="ritual" type="button">Begin the month</button>
    `;
  } else {
    body = `
      <p class="lede">${firstName() ? `${escapeHtml(firstName())}, this stamp was left unmarked. That is all right. Any pages from ${bunny.season} still live here.` : `This stamp was left unmarked. Any pages from ${bunny.season} still live here.`}</p>
      ${pageList || `<p class="lede">No journal from ${bunny.season} ${year}.</p>`}
      <button class="ghost" data-act="close-sheet" type="button">Close</button>
    `;
  }

  haptic(10);
  openOverlay(els.sheet, `
    <section class="sheet charm-detail" role="dialog" aria-labelledby="stamp-title">
      <div class="handle"></div>
      <div class="hero">${charmSvg(bunny, collected)}</div>
      <p class="kicker">${bunny.season} ${year}</p>
      <h2 id="stamp-title">${bunny.name}</h2>
      ${body}
    </section>
  `);
}

function openWelcome() {
  openOverlay(els.ritual, `
    <section class="ritual welcome">
      <p class="kicker">A private sanctuary</p>
      <div class="hero-mark" tabindex="-1">${markSvg("currentColor")}</div>
      <h2 class="welcome-title">What shall we call you?</h2>
      <p class="lede">Just your first name. This stays on this device, and the morning will greet you by it.</p>
      <label class="field">
        <input id="welcome-name" maxlength="24" placeholder="Your name" autocomplete="given-name" />
      </label>
      <button class="primary" type="button" id="save-welcome">This is me</button>
      <button class="skip" type="button" data-act="skip-name">Begin quietly</button>
    </section>
  `);
  const input = document.getElementById("welcome-name");
  input?.focus();
  document.getElementById("save-welcome")?.addEventListener("click", () => {
    const name = input?.value.trim() ?? "";
    if (!name) {
      input?.focus();
      return;
    }
    state.name = name;
    finishWelcome();
  });
  input?.addEventListener("keydown", (event) => {
    if (event.key !== "Enter") return;
    event.preventDefault();
    document.getElementById("save-welcome")?.click();
  });
}

function finishWelcome() {
  state.welcomed = true;
  save();
  haptic([10, 24, 14]);
  closeOverlay(els.ritual);
  render();
  maybeOpenRitual();
}

function maybeOpenRitual() {
  if (!isFirstMorning() || ritualDone() || greetingOffered) return;
  if (els.ritual.classList.contains("is-on")) return;
  greetingOffered = true;
  openRitual();
}

function openSettings() {
  openOverlay(els.sheet, `
    <section class="sheet" role="dialog" aria-labelledby="settings-title">
      <div class="handle"></div>
      <p class="kicker">Preferences</p>
      <h2 id="settings-title">${firstName() ? `This is yours, ${escapeHtml(firstName())}.` : "Keep it yours."}</h2>
      <p class="lede">Quiet settings. Everything stays on this device.</p>
      <label class="field">
        <input id="profile-name" maxlength="24" placeholder="Your name" value="${escapeHtml(firstName())}" />
        <span>How the sanctuary greets you</span>
      </label>
      <div class="setting">
        <div><strong>Haptics</strong><span>A small pulse when luck arrives</span></div>
        <button class="toggle ${state.haptics ? "is-on" : ""}" data-toggle="haptics" aria-pressed="${state.haptics}"></button>
      </div>
      <div class="setting">
        <div><strong>Dark evening</strong><span>Softer light after dusk</span></div>
        <button class="toggle ${state.theme === "dark" ? "is-on" : ""}" data-toggle="theme" aria-pressed="${state.theme === "dark"}"></button>
      </div>
      <div class="setting">
        <div><strong>Preview the first of the month</strong><span>Open today’s greeting as if it were the 1st</span></div>
        <button class="toggle ${state.previewFirst ? "is-on" : ""}" data-toggle="previewFirst" aria-pressed="${state.previewFirst}"></button>
      </div>
      <div class="setting">
        <div><strong>Shared Sanctuary</strong><span>Intentions and stamps, never journal pages</span></div>
        <button class="toggle ${circleState().joined ? "is-on" : ""}" data-act="toggle-circle" aria-pressed="${circleState().joined}"></button>
      </div>
      <div class="setting">
        <div><strong>Add to Home Screen</strong><span>Wear it on your phone</span></div>
        <button class="ghost" data-act="install">Add</button>
      </div>
      <div class="setting">
        <div><strong>This phone’s data</strong><span>Journal pages, check-ins, and stamps as a JSON file</span></div>
        <div class="backup-btns">
          <button class="ghost" type="button" data-act="export-data">Export Data</button>
          <button class="ghost" type="button" data-act="import-data">Import</button>
        </div>
      </div>
      <button class="quiet" type="button" data-act="reset">Clear this device</button>
    </section>
  `);
  document.getElementById("profile-name").addEventListener("change", (event) => {
    state.name = event.target.value.trim();
    state.welcomed = true;
    save();
    haptic(8);
    render();
  });
}

function openInstall() {
  openOverlay(els.sheet, `
    <section class="sheet install-sheet" role="dialog" aria-labelledby="install-title">
      <div class="handle"></div>
      <div class="install-mark">${markSvg("currentColor")}</div>
      <p class="kicker">Keep a little luck close</p>
      <h2 id="install-title">Add White Rabbits to your phone</h2>
      <ol>
        <li><b>1</b>Open this page in Safari.</li>
        <li><b>2</b>Tap the Share button.</li>
        <li><b>3</b>Choose “Add to Home Screen”.</li>
      </ol>
      <button class="ghost" data-act="close-sheet" style="margin-top:22px">Close</button>
    </section>
  `);
}

function toggleHabit(id) {
  const set = todayChecks();
  if (set.has(id)) set.delete(id);
  else {
    set.add(id);
    haptic([8, 18, 12]);
  }
  state.checks[dayKey()] = [...set];
  save();
  render();
}

function appendJournalText(text) {
  const line = String(text ?? "").trim();
  if (!line || line === "Listening...") return;
  const key = dayKey();
  const prev = state.journal[key] ?? {};
  persistPage(key, {
    text: [prev.text, line].filter(Boolean).join(prev.text ? "\n" : ""),
    mood: prev.mood ?? "",
    photo: prev.photo ?? "",
  });
  haptic([8, 16, 10]);
  render();
}

async function saveHomePhoto(file) {
  if (!file) return;
  const photo = await compressImage(file);
  const key = dayKey();
  const prev = state.journal[key] ?? {};
  persistPage(key, { text: prev.text ?? "", mood: prev.mood ?? "", photo });
  haptic(10);
  render();
}

function startHomeVoice() {
  const live = document.getElementById("live-transcript");
  const btn = document.querySelector("[data-act='voice']");
  if (!canListen()) {
    openCompose();
    return;
  }
  const on = btn.classList.toggle("is-on");
  if (!on) {
    stopListening();
    return;
  }
  haptic(8);
  if (live) {
    live.hidden = false;
    live.textContent = "Listening... words become text, nothing is stored as audio.";
  }
  startDictation((text) => {
    if (live) live.textContent = text;
  });
}

function onHero() {
  if (isFirstMorning() && !ritualDone()) openRitual();
  else haptic(10);
}

function onAction(act) {
  if (act === "hero") onHero();
  if (act === "home") { closeOverlay(els.sheet); setTab("home"); }
  if (act === "ritual") { closeOverlay(els.sheet); openRitual(); }
  if (act === "compose") { closeOverlay(els.ritual); openCompose(); }
  if (act === "after-ritual") openIntention();
  if (act === "share-story") shareStory();
  if (act === "intention") openIntention();
  if (act === "habits") openHabits();
  if (act === "voice") startHomeVoice();
  if (act === "journal-photo") document.getElementById("home-photo")?.click();
  if (act === "close-ritual") {
    closeOverlay(els.ritual);
    render();
  }
  if (act === "close-sheet") closeOverlay(els.sheet);
  if (act === "skip-name") finishWelcome();
  if (act === "join-circle") joinCircle();
  if (act === "leave-circle") leaveCircle();
  if (act === "toggle-circle") toggleCircle();
  if (act === "invite-circle") openInvite();
  if (act === "add-friend") openAddFriend();
  if (act === "seen-spark") markSparksSeen();
  if (act === "install") {
    if (installPrompt) { installPrompt.prompt(); installPrompt = null; }
    else openInstall();
  }
  if (act === "settings") openSettings();
  if (act === "export-data") exportData();
  if (act === "import-data") document.getElementById("backup-import")?.click();
  if (act === "reset") {
    state = defaultState();
    greetingOffered = false;
    save();
    applyTheme();
    closeOverlay(els.sheet);
    setTab("home");
  }
}

document.addEventListener("submit", (event) => {
  if (!event.target.closest("[data-whisper]")) return;
  event.preventDefault();
});

document.getElementById("home-photo")?.addEventListener("change", (event) => {
  const file = event.target.files?.[0];
  event.target.value = "";
  saveHomePhoto(file);
});

document.getElementById("backup-import")?.addEventListener("change", (event) => {
  const file = event.target.files?.[0];
  event.target.value = "";
  importBackupFile(file);
});

document.addEventListener("click", (event) => {
  const tabBtn = event.target.closest("[data-tab]");
  if (tabBtn) setTab(tabBtn.dataset.tab);

  const act = event.target.closest("[data-act]");
  if (act) onAction(act.dataset.act);

  const habit = event.target.closest("[data-habit]");
  if (habit) toggleHabit(habit.dataset.habit);

  const compose = event.target.closest("[data-compose]");
  if (compose) openCompose(compose.dataset.compose);

  const charm = event.target.closest("[data-charm]");
  if (charm) openCharm(charm.dataset.charm);

  const stamp = event.target.closest("[data-stamp]");
  if (stamp) openStamp(stamp.dataset.stamp);

  const monthLog = event.target.closest("[data-month-log]");
  if (monthLog) openMonthLog(monthLog.dataset.monthLog);

  const share = event.target.closest("[data-share]");
  if (share) shareStory(Number(share.dataset.share));

  const spark = event.target.closest("[data-spark]");
  if (spark) sendSpark(spark.dataset.spark);

  const release = event.target.closest("[data-release]");
  if (release) releaseFriend(release.dataset.release);

  const remove = event.target.closest("[data-remove]");
  if (remove) {
    state.habits = state.habits.filter((item) => item.id !== remove.dataset.remove);
    save();
    haptic(8);
    openHabits();
    render();
  }

  const toggle = event.target.closest("[data-toggle]");
  if (toggle) {
    const key = toggle.dataset.toggle;
    if (key === "theme") state.theme = state.theme === "dark" ? "light" : "dark";
    else state[key] = !state[key];
    applyTheme();
    save();
    haptic(8);
    if (key === "previewFirst" && state.previewFirst) {
      greetingOffered = false;
      closeOverlay(els.sheet);
      render();
      maybeOpenRitual();
      return;
    }
    openSettings();
    render();
  }

  if (event.target === els.sheet) closeOverlay(els.sheet);
});

els.settingsOpen.addEventListener("click", openSettings);

window.addEventListener("beforeinstallprompt", (event) => {
  event.preventDefault();
  installPrompt = event;
});

document.addEventListener("visibilitychange", () => {
  if (document.visibilityState === "visible") {
    els.kicker.textContent = `${kickers[tab]}  ·  ${monthName()} ${now().getFullYear()}`;
    render();
  }
});

if ("serviceWorker" in navigator) navigator.serviceWorker.register("./sw.js");

setTab("home");

if (!state.welcomed) openWelcome();
else maybeOpenRitual();
