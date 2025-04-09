document.addEventListener("DOMContentLoaded", () => {
  const countEl = document.getElementById("count");
  const roastEl = document.getElementById("roast");
  const mercyToggle = document.getElementById("mercyToggle");

  // Safety check for DOM elements
  if (!countEl || !roastEl || !mercyToggle) {
    console.error("❌ DOM elements not found in popup.");
    return;
  }

  // Load and set Mercy Mode toggle
  chrome.storage.sync.get(['mercyMode'], (data) => {
    mercyToggle.checked = data.mercyMode || false;
  });

  mercyToggle.addEventListener('change', () => {
    chrome.storage.sync.set({ mercyMode: mercyToggle.checked });
  });

  // Get tab count and display roast
  chrome.tabs.query({}, (tabs) => {
    const tabCount = tabs.length;
    countEl.textContent = `Tabs: ${tabCount}`;
    roastEl.textContent = getRoastByTabCount(tabCount);
  });
});

// 🔥 Roast Logic

function pickRandom(list) {
  return list[Math.floor(Math.random() * list.length)];
}

function getRoastByTabCount(count) {
  if (count <= 10) return pickRandom(roastTiers.mild);
  if (count <= 30) return pickRandom(roastTiers.spicy);
  return pickRandom(roastTiers.inferno);
}

const roastTiers = {
  mild: [
    "That's... a lot of tabs. You good?",
    "Tabs don't equal productivity, champ.",
    "Each tab is a tiny cry for help.",
    "I'm not judging, but Chrome is.",
    "Your browser is starting to judge you too.",
    "Every tab is a ghost of your abandoned attention span.",
    "Tab count: concerning. Sanity level: declining.",
    "Even AI doesn't understand what you're doing.",
    "Have you considered... bookmarks?",
    "Your productivity is a beautiful illusion.",
    "Close 10 tabs, gain +5 mental stability.",
    "Google just flagged your activity as 'suspiciously extra.'",
    "This is a monument to indecision.",
    "That’s not multitasking, that’s hoarding.",
    "You're one 'new tab' away from the void.",
    "Even your bookmarks are screaming."
  ],
  spicy: [
    "Your RAM is crying.",
    "NASA called. They want their CPU back.",
    "Your browser is now sentient.",
    "Your tabs are unionizing.",
    "Is this your villain arc?",
    "You could build a second internet with this many tabs.",
    "Your CPU just submitted its resignation letter.",
    "This is why we can't have nice things.",
    "Your laptop fan just called for backup.",
    "Tabs aren't infinity stones. Stop collecting them.",
    "Somewhere, a browser developer is weeping.",
    "You're gonna crash harder than Internet Explorer in 2005.",
    "Even Firefox is side-eyeing you right now.",
    "Are you opening tabs or summoning demons?",
    "You're the reason task managers exist.",
    "Your browser history is just pure chaos.",
    "This is digital gluttony at its finest.",
    "You’re building your own digital multiverse.",
    "The tabs have tabs now.",
    "You’re one click away from a BSOD.",
    "I bet your taskbar looks like a ticker tape.",
    "If you opened one more tab, you'd summon Clippy from the underworld."
  ],
  inferno: [
    "Are you researching something or committing digital war crimes?",
    "Your computer is legally considered a war zone.",
    "This many tabs should be a felony.",
    "If tabs were brain cells, you'd be a genius. But you're not.",
    "This is less of a browser and more of a black hole.",
    "I showed this to a sysadmin and they fainted.",
    "You need help. Professional, spiritual, maybe both.",
    "If tabs were sins, you’re beyond redemption.",
    "Your tab collection has surpassed your life goals.",
    "Congratulations. You broke the internet.",
    "You've achieved full goblin mode.",
    "Your browser fan is audible in another room.",
    "At this point, even your tabs have tabs.",
    "You've reached a level of multitasking unknown to mankind.",
    "You’re the reason Chrome eats 12GB of RAM.",
    "You're actively summoning Skynet through tabs alone.",
    "This isn’t just hoarding — it’s digital necromancy.",
    "This tab count is a personality disorder.",
    "This is what happens when chaos gets Wi-Fi.",
    "I'm not saying you're broken, but your browser sure is."
  ]
};
