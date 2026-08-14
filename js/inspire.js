/** Monthly secular light. Original lines. Inclusive, no doctrine. */

export const MONTHLY_LIGHT = [
  [
    { line: "The year is still frost and possibility.", prompt: "What wants a slow beginning?" },
    { line: "Even the shortest days keep a pale gold.", prompt: "Where is the light arriving first?" },
    { line: "Quiet is a kind of weather too.", prompt: "What can stay unhurried this morning?" },
    { line: "New pages do not ask to be filled at once.", prompt: "What is one true sentence for today?" },
  ],
  [
    { line: "Under the soil, something is already reaching.", prompt: "What is stirring, even if you cannot see it?" },
    { line: "Tenderness is a form of attention.", prompt: "Who or what could use a gentler look?" },
    { line: "Early colour returns before we are ready.", prompt: "What small colour did you notice?" },
    { line: "The heart learns the season in its own time.", prompt: "What feels ready, and what can wait?" },
  ],
  [
    { line: "Light and dark share the hours as equals.", prompt: "Where do you need a little more balance?" },
    { line: "The first green is a quiet courage.", prompt: "What is just beginning to show?" },
    { line: "Wind moves the old leaves so the new can breathe.", prompt: "What can you let loosen today?" },
    { line: "Equinox is a pause, not a test.", prompt: "What would a fairer day look like?" },
  ],
  [
    { line: "Rain is how the ground drinks.", prompt: "What is feeding you quietly?" },
    { line: "Growth prefers weather to willpower.", prompt: "Where can you stop forcing and start allowing?" },
    { line: "A wet morning still belongs to you.", prompt: "What would make today feel possible?" },
    { line: "Seeds do not apologise for taking time.", prompt: "What are you willing to tend without rushing?" },
  ],
  [
    { line: "Blossom is brief, and that is part of its honesty.", prompt: "What is open in you right now?" },
    { line: "The air has learned a softer temperature.", prompt: "How does the morning feel on your skin?" },
    { line: "Petals fall and the tree is not diminished.", prompt: "What can you release without losing yourself?" },
    { line: "May is an invitation, not a demand.", prompt: "What would you say yes to, lightly?" },
  ],
  [
    { line: "The longest light asks only that you notice it.", prompt: "Where will you stand in the sun today?" },
    { line: "Warmth is a kind of luck we can share.", prompt: "Who could use a little of your warmth?" },
    { line: "Midsummer does not hurry, and neither must you.", prompt: "What can take the whole day?" },
    { line: "Leaves are busy making the shade you will need.", prompt: "What are you making for later, without strain?" },
  ],
  [
    { line: "Heat teaches the body to move more slowly.", prompt: "Where can you choose ease over effort?" },
    { line: "Ripe things ask to be enjoyed, not earned.", prompt: "What is already enough this morning?" },
    { line: "The day is full. You do not have to be.", prompt: "What can stay simple?" },
    { line: "Gold in the evening is the same light, arriving home.", prompt: "How do you want to close the day?" },
  ],
  [
    { line: "Golden hour lives in ordinary rooms too.", prompt: "What is catching the light this morning?" },
    { line: "Harvest begins with noticing what has grown.", prompt: "What have you already gathered this year?" },
    { line: "August keeps the warmth and hints at turning.", prompt: "What are you ready to carry forward?" },
    { line: "The field does not boast. It simply ripens.", prompt: "What in you is quietly ready?" },
  ],
  [
    { line: "The first cool morning is a kindness.", prompt: "What feels clearer in this air?" },
    { line: "Leaves turn without being told it is time.", prompt: "What change can you meet without argument?" },
    { line: "A harvest moon is only the sun, remembered at night.", prompt: "What light are you keeping for later?" },
    { line: "September is a long exhale.", prompt: "What can you set down?" },
  ],
  [
    { line: "Dusk arrives earlier, and the room grows intimate.", prompt: "What do you want closer this month?" },
    { line: "Fallen leaves are not a failure of the tree.", prompt: "What ending can you treat as natural?" },
    { line: "The beautiful dark is still a kind of shelter.", prompt: "Where do you feel safely held?" },
    { line: "October asks for gathering in, not giving up.", prompt: "What is worth keeping near?" },
  ],
  [
    { line: "Embers are the fire, practising rest.", prompt: "What warmth remains if you stop pushing?" },
    { line: "The low sun still knows your face.", prompt: "Where will you put yourself in the light?" },
    { line: "Bare branches make the sky easier to see.", prompt: "What becomes visible when you simplify?" },
    { line: "November is a hearth month.", prompt: "What would make today feel like coming home?" },
  ],
  [
    { line: "The longest night still contains a small light.", prompt: "What tiny light are you keeping?" },
    { line: "Stars do not compete. They simply appear.", prompt: "Where can you stop comparing and just be?" },
    { line: "Winter is not empty. It is storing.", prompt: "What are you allowing to rest?" },
    { line: "A year ends the way a day does: with permission to begin again.", prompt: "What do you want to carry into the next morning?" },
  ],
];

export function todayInspiration(date = new Date()) {
  const pool = MONTHLY_LIGHT[date.getMonth()] ?? MONTHLY_LIGHT[0];
  const item = pool[(date.getDate() - 1) % pool.length];
  const kicker = new Intl.DateTimeFormat("en-GB", { month: "long" }).format(date) + " light";
  return { ...item, kicker };
}
