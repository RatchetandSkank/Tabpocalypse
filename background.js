// background.js
const roastTiers = {
  mild: [
    "That's... a lot of tabs. You good?",
    "Tabs don't equal productivity, champ.",
    "Each tab is a tiny cry for help.",
    "I’m not judging, but Chrome is.",
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
    "You’re the reason this browser eats 12GB of RAM.",
    "You're actively summoning Skynet through tabs alone.",
    "This isn’t just hoarding — it’s digital necromancy.",
    "This tab count is a personality disorder.",
    "This is what happens when chaos gets Wi-Fi.",
    "I'm not saying you're broken, but your browser sure is."
  ]
};

function pickRandom(list) {
  return list[Math.floor(Math.random() * list.length)];
}

function getRoastByTabCount(tabCount) {
  if (tabCount <= 10) return pickRandom(roastTiers.mild);
  if (tabCount <= 30) return pickRandom(roastTiers.spicy);
  return pickRandom(roastTiers.inferno);
}

function updateRoastStats(currentTabCount) {
  chrome.storage.local.get(['peakTabCount', 'totalRoasts'], (data) => {
    const newPeak = Math.max(data.peakTabCount || 0, currentTabCount);
    const newTotal = (data.totalRoasts || 0) + 1;

    chrome.storage.local.set({
      peakTabCount: newPeak,
      totalRoasts: newTotal
    });
  });
}

function checkTabsAndRoast() {
  chrome.storage.sync.get(['mercyMode'], (settings) => {
    if (settings.mercyMode) return;

    chrome.tabs.query({}, (tabs) => {
      const tabCount = tabs.length;
      console.log("🔍 Current tab count:", tabCount);

      if (tabCount > 4 && Math.random() < 0.25) {
        const roast = getRoastByTabCount(tabCount);
        console.log("🔥 Roast selected:", roast);

        chrome.notifications.create('', {
          type: 'basic',
          iconUrl: 'icon.png',
          title: 'Tabpocalypse',
          message: roast
        }, (id) => {
          if (chrome.runtime.lastError) {
            console.error("Notification error:", chrome.runtime.lastError.message);
          } else {
            console.log("✅ Notification sent:", id);
          }
        });

        tabs.forEach(tab => {
          if (tab.id) {
            chrome.scripting.executeScript({
              target: { tabId: tab.id },
              func: (message) => {
                const id = "tabpocalypse-roast";
                if (document.getElementById(id)) return;

                const roastDiv = document.createElement("div");
                roastDiv.id = id;
                roastDiv.textContent = message;

                Object.assign(roastDiv.style, {
                  position: "fixed",
                  bottom: "20px",
                  right: "20px",
                  backgroundColor: "#ff4d4d",
                  color: "#fff",
                  padding: "12px 16px",
                  fontSize: "16px",
                  fontFamily: "Arial, sans-serif",
                  borderRadius: "8px",
                  boxShadow: "0 0 10px rgba(0,0,0,0.3)",
                  zIndex: 999999,
                  maxWidth: "300px"
                });

                document.body.appendChild(roastDiv);
                setTimeout(() => roastDiv.remove(), 10000);
              },
              args: [roast]
            });
          }
        });

        updateRoastStats(tabCount);
        chrome.action.setBadgeText({ text: String(tabCount) });
        chrome.action.setBadgeBackgroundColor({ color: "#ff4d4d" });
      } else {
        console.log("😎 Tab count is chill or RNG said nope.");
      }
    });
  });
}

function getRandomInterval() {
  return Math.floor(Math.random() * 5) + 1;
}

chrome.runtime.onInstalled.addListener(() => {
  console.log("🚀 Tabpocalypse initialized.");
  chrome.alarms.create('roastCheck', {
    delayInMinutes: 1,
    periodInMinutes: getRandomInterval()
  });
});

chrome.alarms.onAlarm.addListener((alarm) => {
  if (alarm.name === 'roastCheck') {
    checkTabsAndRoast();

    chrome.alarms.clear('roastCheck', () => {
      chrome.alarms.create('roastCheck', {
        delayInMinutes: getRandomInterval(),
        periodInMinutes: getRandomInterval()
      });
    });
  }
});
