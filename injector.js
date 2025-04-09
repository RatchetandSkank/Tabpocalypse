console.log("✅ injector.js loaded into page");

chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  console.log("📩 Message received in content script:", request);

  if (request.action === "injectRoast") {
    injectRoastDiv(request.message);
  }
});

function injectRoastDiv(message) {
  if (document.getElementById("tabpocalypse-roast")) return; // Don't duplicate

  const roastDiv = document.createElement("div");
  roastDiv.id = "tabpocalypse-roast";
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

  setTimeout(() => {
    roastDiv.remove();
  }, 10000);
}
