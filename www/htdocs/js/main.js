$("button").click((event)=>{
  const id = event.target.dataset.id;
  if (id == 'tempty') {
     $('tr.empty').fadeToggle("fast");
     $('.kek').remove();
  }
  else {
    $('tr[data-id="'+id+'_details"]').fadeToggle("fast");
  }
});
