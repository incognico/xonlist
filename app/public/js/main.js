$(document).ready(function() {
  const table = document.getElementById("main");
  const tbody = table && table.tBodies[0];
  const filter = document.getElementById("filter");
  const emptyBtn = document.querySelector(".tempty");
  let showEmpty = false;

  if (!tbody) {
    return;
  }

  const rows = [];
  const infos = tbody.querySelectorAll("tr.info");
  for (let i = 0; i < infos.length; i++) {
    const info = infos[i];
    const next = info.nextElementSibling;
    const details = next && next.classList.contains("details") ? next : null;
    rows.push({
      info: info,
      details: details,
      empty: info.classList.contains("empty"),
      text: ((info.textContent || "") + "\n" + (details ? details.textContent || "" : "")).toLowerCase()
    });
  }

  function query() {
    return ((filter && filter.value) || "").toLowerCase().trim();
  }

  function apply() {
    const q = query();
    let vis = 0;

    for (let i = 0; i < rows.length; i++) {
      const row = rows[i];
      const hit = !q || row.text.indexOf(q) !== -1;
      const show = hit && (!row.empty || showEmpty || q.length > 0);

      row.info.classList.toggle("hidden", !show);
      if (row.details && !show) {
        row.details.classList.add("hidden");
      }

      const alt = show && (vis++ % 2 === 1);
      row.info.classList.toggle("alt", alt);
      if (row.details) {
        row.details.classList.toggle("alt", alt);
      }
    }

    table.classList.add("js-stripes");
    if (emptyBtn) {
      emptyBtn.classList.toggle("is-on", showEmpty);
      emptyBtn.setAttribute("aria-pressed", showEmpty ? "true" : "false");
    }
  }

  if (filter) {
    filter.addEventListener("input", apply);
  }

  document.addEventListener("click", function(event) {
    const btn = event.target.closest && event.target.closest("button[data-id]");
    if (!btn) {
      return;
    }
    const id = btn.dataset.id;
    if (id === "tempty") {
      showEmpty = !showEmpty;
      apply();
      btn.blur();
      return;
    }
    const info = tbody.querySelector('tr.info[data-id="' + CSS.escape(id) + '"]');
    if (!info || info.classList.contains("hidden")) {
      return;
    }
    const details = info.nextElementSibling;
    if (details && details.classList.contains("details")) {
      details.classList.toggle("hidden");
    }
  });

  const params = new URLSearchParams(window.location.search);
  const single = params.get("single");
  const qParam = params.get("q");
  if (qParam && filter) {
    filter.value = qParam;
  }
  if (single && filter) {
    filter.value = single;
    showEmpty = true;
  }

  apply();

  if (single) {
    const info = tbody.querySelector('tr.info[data-id="' + CSS.escape(single) + '"]');
    if (info && info.nextElementSibling) {
      info.nextElementSibling.classList.remove("hidden");
    }
  }

  document.addEventListener("colorschemechange", apply);
});

clipboard.on("success", function(e) {
  var ele = e.trigger;
  e.clearSelection();
  ele.blur();
  ele.innerHTML = "&#x2714;&#xfe0f;";
  setTimeout(revert, 6000, ele);
});

function revert(ele) {
  ele.innerHTML = "&#x1f517;";
}
