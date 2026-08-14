/** Shared Sanctuary. Public cards only: name, intention, stamp. Never journal. */

import { BUNNIES, bunnyByMonth } from "./bunnies.js";

const FELLOWS = [
  { id: "fellow-mira", name: "Mira", intention: "Keep the mornings slow" },
  { id: "fellow-jonah", name: "Jonah", intention: "Make one true thing" },
  { id: "fellow-sylvie", name: "Sylvie", intention: "Leave room for luck" },
  { id: "fellow-kenji", name: "Kenji", intention: "Protect the quiet hours" },
  { id: "fellow-noor", name: "Noor", intention: "Begin with softness" },
];

export function sparkSvg() {
  return `
    <svg viewBox="0 0 18 18" fill="currentColor" aria-hidden="true">
      <path d="M9 1.6l1.35 5.15L15.4 8 10.35 9.25 9 14.4 7.65 9.25 2.6 8l5.05-1.25z"/>
    </svg>
  `;
}

export function fellowCards(date = new Date()) {
  const month = date.getMonth() + 1;
  const year = date.getFullYear();
  const bunny = bunnyByMonth(month);
  const start = date.getMonth() % FELLOWS.length;
  return Array.from({ length: 4 }, (_, i) => {
    const fellow = FELLOWS[(start + i) % FELLOWS.length];
    return {
      ...fellow,
      month,
      year,
      charmId: bunny.id,
      kind: "fellow",
    };
  });
}

export function defaultCircle() {
  return {
    joined: false,
    seenIntro: false,
    id: "",
    friends: [],
    sparksGiven: {},
    sparksReceived: [],
  };
}

export function encodeCard(card) {
  const payload = {
    v: 1,
    id: card.id,
    name: String(card.name || "A friend").slice(0, 24),
    month: Number(card.month),
    year: Number(card.year),
    intention: String(card.intention || "").slice(0, 80),
    charmId: card.charmId,
  };
  return `WR1.${toB64url(JSON.stringify(payload))}`;
}

export function decodeCard(token) {
  const raw = String(token ?? "").trim();
  if (!raw) return null;
  const body = raw.startsWith("WR1.") ? raw.slice(4) : raw;
  try {
    const data = JSON.parse(fromB64url(body));
    const month = Number(data.month);
    const year = Number(data.year);
    const intention = String(data.intention || "").trim().slice(0, 80);
    if (!intention || month < 1 || month > 12 || !year) return null;
    const known = BUNNIES.some((bunny) => bunny.id === data.charmId);
    return {
      id: String(data.id || `friend-${Date.now()}`).slice(0, 80),
      name: String(data.name || "A friend").trim().slice(0, 24) || "A friend",
      month,
      year,
      intention,
      charmId: known ? data.charmId : bunnyByMonth(month).id,
      kind: "friend",
    };
  } catch {
    return null;
  }
}

function toB64url(text) {
  const bytes = new TextEncoder().encode(text);
  let binary = "";
  bytes.forEach((byte) => { binary += String.fromCharCode(byte); });
  return btoa(binary).replaceAll("+", "-").replaceAll("/", "_").replaceAll("=", "");
}

function fromB64url(text) {
  const padded = text.replaceAll("-", "+").replaceAll("_", "/");
  const pad = padded.length % 4 === 0 ? "" : "=".repeat(4 - (padded.length % 4));
  const binary = atob(padded + pad);
  return new TextDecoder().decode(Uint8Array.from(binary, (ch) => ch.charCodeAt(0)));
}
