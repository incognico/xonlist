// TODO:
// - make everything searchable including inner table but do not toggle in inner table
// - make it work with the "show empty servers" button, maybe change that to "toggle empty servers"
// - fix :nth striping after event was triggered

$(document).ready(function(){
  $("#filter").on("keyup search", function() {
    var value = $(this).val().toLowerCase();
    $("#main tbody > tr.info").filter(function() {
      $(this).toggle($(this).text().toLowerCase().indexOf(value) > -1);
    });
  });
});

$("button").click((event)=>{
  const id = event.target.dataset.id;
  if (id == 'tempty') {
     $('tr.empty').toggle();
     $('.kek').remove();
  }
  else {
    $('tr[data-id="'+id+'_details"]').toggle();
  }
});

clipboard.on('success', function(e) {
  var ele = e.trigger;
  e.clearSelection();
  clearTimeout();
  ele.blur();
  ele.innerHTML = '&#x2714;&#xfe0f;';
  setTimeout(revert, 6000, ele);
});

function revert(ele) {
  ele.innerHTML = '&#x1f517;';
}
