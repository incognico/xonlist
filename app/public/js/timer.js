var ele = document.getElementById("timer");

if (ele) {
  var zeit = ele.innerText;
  var span = 0;

  function zeita() {
    zeit++;

    if (zeit % 2) {
      ele.innerText = zeit;
    }

    if (span == 0 && zeit > 310) {
      activateSpan();
      span++;
    }
  }

  function activateSpan() {
    var x = document.getElementById("refresh");
      x.style.display = "inline";
  }

  setInterval(zeita, 1000); 
}
