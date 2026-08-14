/** Seasonal collectible charms. Fashion-house marks, not mascots. */

export const BUNNIES = [
  {
    id: "frost",
    month: 1,
    name: "Frost",
    season: "January",
    fill: "#E8EEF2",
    stroke: "#8A97A3",
    accent: "#B7C4CE",
    line: "A quiet white beginning. The year is still unwritten.",
  },
  {
    id: "darling",
    month: 2,
    name: "Darling",
    season: "February",
    fill: "#F3E4E4",
    stroke: "#B3888C",
    accent: "#D4A8AC",
    line: "A small tenderness, kept close.",
  },
  {
    id: "equinox",
    month: 3,
    name: "Equinox",
    season: "March",
    fill: "#E7EDE3",
    stroke: "#7E9174",
    accent: "#A9B89A",
    line: "Light and dark in equal measure. Begin in balance.",
  },
  {
    id: "shower",
    month: 4,
    name: "Shower",
    season: "April",
    fill: "#E6EEF2",
    stroke: "#7E93A1",
    accent: "#A7BCC8",
    line: "What falls, feeds. Let the month arrive softly.",
  },
  {
    id: "blossom",
    month: 5,
    name: "Blossom",
    season: "May",
    fill: "#F6E8EA",
    stroke: "#C08B93",
    accent: "#E0B4BA",
    line: "A brief, perfect opening.",
  },
  {
    id: "solstice",
    month: 6,
    name: "Solstice",
    season: "June",
    fill: "#F4EBD4",
    stroke: "#C4A15A",
    accent: "#E0C57A",
    line: "The longest light. Stay in it a little longer.",
  },
  {
    id: "heat",
    month: 7,
    name: "Heat",
    season: "July",
    fill: "#F3E4D6",
    stroke: "#C08A68",
    accent: "#E0B089",
    line: "Warmth as a kind of luck.",
  },
  {
    id: "harvest",
    month: 8,
    name: "Harvest",
    season: "August",
    fill: "#F3E6C8",
    stroke: "#C4A36A",
    accent: "#E2C888",
    line: "Golden hour, gathered. The year begins to glow.",
  },
  {
    id: "goldleaf",
    month: 9,
    name: "Goldleaf",
    season: "September",
    fill: "#F0E2C4",
    stroke: "#B8954E",
    accent: "#D4B56A",
    line: "A harvest moon, and the first cool morning.",
  },
  {
    id: "shadow",
    month: 10,
    name: "Shadow",
    season: "October",
    fill: "#EDE4DC",
    stroke: "#5C4A5A",
    accent: "#C4A36A",
    line: "A Halloween charm. The beautiful dark, worn lightly.",
  },
  {
    id: "ember",
    month: 11,
    name: "Ember",
    season: "November",
    fill: "#F0E0D0",
    stroke: "#A07858",
    accent: "#C4A07A",
    line: "What remains after the fire. Still warm.",
  },
  {
    id: "starlight",
    month: 12,
    name: "Starlight",
    season: "December",
    fill: "#EEE8DC",
    stroke: "#8A7E68",
    accent: "#D4C48A",
    line: "A small light, kept for the longest night.",
  },
];

function rabbitBody(stroke, fill) {
  return `
    <ellipse cx="42" cy="58" rx="17" ry="14.5" fill="${fill}" stroke="${stroke}" stroke-width="1.6"/>
    <path d="M29 34C27.2 12 33.5 5.5 37.2 24.5" fill="${fill}" stroke="${stroke}" stroke-width="1.6" stroke-linecap="round"/>
    <path d="M41 31C47.5 11 55 14.5 45.5 33" fill="${fill}" stroke="${stroke}" stroke-width="1.6" stroke-linecap="round"/>
    <ellipse cx="37.5" cy="39" rx="12.2" ry="11" fill="${fill}" stroke="${stroke}" stroke-width="1.6"/>
    <circle cx="58.5" cy="59" r="4.6" fill="${fill}" stroke="${stroke}" stroke-width="1.5"/>
    <circle cx="33.2" cy="38.2" r="1.35" fill="${stroke}"/>
    <path d="M28.5 41.5c2.2 2.4 5.4 2.6 7.8.4" fill="none" stroke="${stroke}" stroke-width="1.15" stroke-linecap="round"/>
  `;
}

function scarf(a) {
  return `
    <path d="M26 47c7 5.5 18 6.2 26 1.2" fill="none" stroke="${a}" stroke-width="2.5" stroke-linecap="round"/>
    <path d="M47 49c1.4 7.5 0.2 13-3.2 17" fill="none" stroke="${a}" stroke-width="2.3" stroke-linecap="round"/>
    <path d="M41.5 65.5h9.5" stroke="${a}" stroke-width="1.3" stroke-linecap="round"/>
  `;
}

const PROPS = {
  frost: (a) => `
    ${scarf(a)}
    <path d="M16 16l.2 6M13.2 19h6" stroke="${a}" stroke-width="1.15" stroke-linecap="round"/>
    <path d="M64 14l.15 5.5M61.2 16.7h5.6" stroke="${a}" stroke-width="1.15" stroke-linecap="round"/>
  `,
  darling: (a) => `
    <path d="M30 22c0-1.7 1.3-2.8 2.6-2.8.9 0 1.7.5 2.1 1.3.4-.8 1.2-1.3 2.1-1.3 1.3 0 2.6 1.1 2.6 2.8 0 3-4.7 5.4-4.7 5.4S30 25 30 22z" fill="${a}"/>
    <path d="M62 20c0-2.2 1.6-3.6 3.2-3.6 1.2 0 2.2.6 2.6 1.6.4-1 1.4-1.6 2.6-1.6 1.6 0 3.2 1.4 3.2 3.6 0 3.8-5.8 6.8-5.8 6.8S62 23.8 62 20z" fill="${a}"/>
  `,
  equinox: (a) => `
    <path d="M28 20c-1.2-4.5 1.4-8 2.2-8 .8 0 3.4 3.5 2.2 8" fill="${a}" opacity=".9"/>
    <path d="M40 16c-1-4.2 1.6-7.6 2.4-7.6s3.4 3.4 2.2 7.6" fill="${a}"/>
    <path d="M50 21c-1-3.6 1.2-6.4 2-6.4s2.8 2.8 1.8 6.4" fill="${a}" opacity=".85"/>
  `,
  shower: (a) => `
    <path d="M18 18c0 2.4-1.7 3.6-1.7 5.4A1.7 1.7 0 0018 25.1a1.7 1.7 0 001.7-1.7C19.7 21.6 18 20.4 18 18z" fill="${a}"/>
    <path d="M26 14c0 2-1.4 3-1.4 4.6A1.4 1.4 0 0026 20a1.4 1.4 0 001.4-1.4C27.4 17 26 16 26 14z" fill="${a}" opacity=".7"/>
    <path d="M66 18c0 2.3-1.6 3.5-1.6 5.2A1.6 1.6 0 0066 24.8a1.6 1.6 0 001.6-1.6C67.6 21.5 66 20.3 66 18z" fill="${a}"/>
    <path d="M58 16c4 0 7 2 8 5H50c1-3 4-5 8-5z" fill="${a}" opacity=".8"/>
  `,
  blossom: (a) => `
    <g fill="${a}">
      <circle cx="28" cy="18" r="3"/>
      <circle cx="35" cy="14" r="3.2"/>
      <circle cx="43" cy="13.5" r="3"/>
      <circle cx="50" cy="17" r="2.8"/>
      <circle cx="32" cy="22" r="2.4" opacity=".75"/>
      <circle cx="46" cy="21" r="2.3" opacity=".75"/>
    </g>
  `,
  solstice: (a) => `
    <g transform="translate(40 12)" stroke="${a}" stroke-width="1.15" stroke-linecap="round">
      <circle cx="0" cy="0" r="4" fill="${a}" stroke="none"/>
      <path d="M0-8.2v2.2M0 6v2.2M-8.2 0h2.2M6 0h2.2M-5.8-5.8l1.6 1.6M4.2 4.2l1.6 1.6M-5.8 5.8l1.6-1.6M4.2-4.2l1.6-1.6"/>
    </g>
  `,
  heat: (a) => `
    <circle cx="40" cy="16" r="5" fill="${a}" opacity=".9"/>
    <path d="M16 48c4-8 4-14 0-20" fill="none" stroke="${a}" stroke-width="1.3" stroke-linecap="round"/>
    <path d="M22 50c3.4-6.5 3.4-12 0-17" fill="none" stroke="${a}" stroke-width="1.15" stroke-linecap="round" opacity=".7"/>
  `,
  harvest: (a) => `
    <path d="M22 24c4-6 10-8 14-6-2 5-8 8-14 6z" fill="${a}"/>
    <path d="M50 18c5-5 12-5 16-1-4 4-11 6-16 1z" fill="${a}"/>
    <path d="M14 62c8-18 6-28 2-38" fill="none" stroke="${a}" stroke-width="1.3" stroke-linecap="round"/>
    <path d="M16 36c-4-1-6 2-4 5M16 42c-4-1-6 2-4 5M16 48c-4-1-6 2-4 5" fill="none" stroke="${a}" stroke-width="1.15" stroke-linecap="round"/>
  `,
  goldleaf: (a) => `
    <path d="M26 18c-5 3.5-6.5 9-4.5 13 7-1.5 10.5-7 8.5-12.2-1.6 1.2-3.2 1.4-4 1.4s.6-1.8 0-2.2z" fill="${a}"/>
    <path d="M50 14c-5.5 4-7 10-4.8 14.5 8-2 12-8 10-14-2 1.3-3.8 1.5-4.2 1.5s.8-2 1-2z" fill="${a}"/>
    <path d="M66 22a7.2 7.2 0 107.4 8.6 5.8 5.8 0 01-7.4-8.6z" fill="${a}" opacity=".9"/>
  `,
  shadow: (a, s) => `
    <path d="M32 7.5l8.2 16.5H23.8z" fill="${s}" opacity=".92"/>
    <path d="M23.8 24h16.4v2.2H23.8z" fill="${s}"/>
    <path d="M24 46c-2 8 0 16 4 20" fill="none" stroke="${s}" stroke-width="1.6" stroke-linecap="round" opacity=".7"/>
    <ellipse cx="68" cy="22" rx="5.2" ry="4.2" fill="${a}" opacity=".9"/>
    <path d="M68 26.2v3.4" stroke="${a}" stroke-width="1.2"/>
  `,
  ember: (a) => `
    ${scarf(a)}
    <path d="M64 16c-5.5 3.5-7 9-5 14.2 7.2-1.8 11-7.2 9-13-1.8 1.2-3.4 1.4-4 1.4s.7-2 0-2.6z" fill="${a}"/>
  `,
  starlight: (a) => `
    ${scarf(a)}
    <path d="M40 8.5l1.15 3.5h3.7l-3 2.2 1.15 3.5L40 15.6l-3 2.1 1.15-3.5-3-2.2h3.7z" fill="${a}"/>
    <path d="M18 20l.7 2.1h2.2l-1.8 1.35.7 2.15L18 24.4l-1.8 1.3.7-2.15-1.8-1.35h2.2z" fill="${a}" opacity=".8"/>
  `,
};

const SUMMER_GLOW = new Set(["solstice", "heat", "harvest"]);

export function bunnyByMonth(month) {
  return BUNNIES.find((b) => b.month === month) ?? BUNNIES[0];
}

export function charmSvg(bunny, unlocked) {
  const stroke = unlocked ? bunny.stroke : "currentColor";
  const fill = unlocked ? bunny.fill : "transparent";
  const accent = unlocked ? bunny.accent : "currentColor";
  const prop = PROPS[bunny.id]?.(accent, stroke) ?? "";
  const glow = unlocked && SUMMER_GLOW.has(bunny.id)
    ? `<circle cx="40" cy="42" r="36" fill="${bunny.accent}" opacity=".28"/>`
    : unlocked ? `<circle cx="40" cy="42" r="36" fill="${bunny.fill}" opacity=".35"/>` : "";
  return `
    <svg viewBox="0 0 80 80" aria-hidden="true">
      ${glow}
      ${rabbitBody(stroke, fill)}
      ${prop}
    </svg>
  `;
}

export function markSvg(stroke = "currentColor", fill = "transparent") {
  return `
    <svg viewBox="0 0 80 80" aria-hidden="true">
      ${rabbitBody(stroke, fill)}
    </svg>
  `;
}
