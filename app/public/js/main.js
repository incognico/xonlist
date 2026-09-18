$(document).ready(function() {
  const $table = $("#main");
  const $tbody = $table.children("tbody");
  const $filter = $("#filter");
  const $emptyBtn = $(".tempty");
  let showEmpty = false;

  if (!$tbody.length) {
    return;
  }

  function query() {
    return ($filter.val() || "").toLowerCase().trim();
  }

  function matches($info, q) {
    if (!q) {
      return true;
    }
    const $details = $info.next("tr.details");
    const hay = ($info.text() + "\n" + $details.text()).toLowerCase();
    return hay.indexOf(q) !== -1;
  }

  function apply() {
    const q = query();
    let vis = 0;

    $tbody.children("tr.info").each(function() {
      const $info = $(this);
      const $details = $info.next("tr.details");
      const empty = $info.hasClass("empty");
      const show = matches($info, q) && (!empty || showEmpty);

      $info.toggleClass("hidden", !show);
      if (!show) {
        $details.addClass("hidden");
      }

      const alt = show && (vis++ % 2 === 1);
      $info.toggleClass("alt", alt);
      $details.toggleClass("alt", alt);
    });

    $table.addClass("js-stripes");
    $emptyBtn.toggleClass("is-on", showEmpty);
    $emptyBtn.attr("aria-pressed", showEmpty ? "true" : "false");
  }

  $filter.on("input keyup search", apply);

  $(document).on("click", "button[data-id]", function(event) {
    const id = event.currentTarget.dataset.id;
    if (id === "tempty") {
      showEmpty = !showEmpty;
      apply();
      event.currentTarget.blur();
      return;
    }
    const $info = $tbody.children('tr.info[data-id="' + id + '"]');
    if ($info.hasClass("hidden")) {
      return;
    }
    $info.next("tr.details").toggleClass("hidden");
  });

  const params = new URLSearchParams(window.location.search);
  const single = params.get("single");
  const qParam = params.get("q");
  if (qParam) {
    $filter.val(qParam);
  }
  if (single) {
    $filter.val(single);
    showEmpty = true;
  }

  apply();

  if (single) {
    $tbody.children('tr.info[data-id="' + single + '"]').next("tr.details").removeClass("hidden");
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
