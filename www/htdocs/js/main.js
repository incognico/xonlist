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
