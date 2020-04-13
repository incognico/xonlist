// TODO:
// - make everything searchable including inner table but do not toggle in inner table
// - make it work with the "show empty servers" button, maybe change that to "toggle empty servers"
// - fix :nth striping after event was triggered

const keysToSkip = [
	"d0id",
	"status",
	"stats",
	"maxspectators",
	"numspectators",
	"numbots",
	"address",
	"enc",
	"fballowed",
	"impure",
	"numplayers",
	"maxplayers",
	"teamplay",
	"slots",
	"ping"
];

const keysInDetails = [
	"version",
	"player"
];

let isBusy = false;
let serverResp = {};
let serversWithOpenDescription = {};

$(document).ready(function() {
  update();
 
  $("#filter").on("keyup search", function() {
	if (isBusy)
	  return;
    isBusy = true;

    let searchQuery = $(this).val().toLowerCase();
    /*$("#main tbody > tr.info").filter(function() {
      $(this).toggle($(this).text().toLowerCase().indexOf(value) > -1);
    });*/
	let searchResults = search(searchQuery);
	if (searchResults.length == 0) {
      // TODO: tell user that no servers found
	} else {
      // TODO: render results in table
      console.log(searchResults);
	}
   isBusy = false;
  });
});

function update() {
  if (isBusy) {
    alert("Can't update: search is in progress.");
	return;
  }
  isBusy = true;
  
  let request = new XMLHttpRequest();
  request.open("GET", "https://xonotic.lifeisabug.com/endpoint/json", true);
  request.onload = function(e) {
	if (request.readyState === 4) {
      if (request.status === 200) {
		serverResp = JSON.parse(request.responseText);
		renderTable();
      } else {
        console.error(request.statusText);
      }
	}
	isBusy = false;
  };
  request.onerror = function(e) {
	let message = "Error " + request.responseText + ": " + request.statusText;
	alert(message);
	console.error(message);
	isBusy = false;
  };
  request.send(null);
}

function renderTable(serverList) {
  //
}

function search(searchQuery) {
  result = [];
  if (searchQuery == "") {
    return Object.keys(serverResp.server);
  }
  for (let server_key in serverResp.server) {
    let containsSearchEntry = false;
    let server = serverResp.server[server_key];
    let lastKey = "";

    Object.entries(server).every(
	   function([key, value]) {
        if (keysToSkip.includes(key))
		  return true;
	    
		lastKey = key;
        if (key != "player" && value.toString().toLowerCase().indexOf(searchQuery) > -1) {
          containsSearchEntry = true;
          return false;
        }
		
        if (key == "player") {
          Object.entries(value).every(
		    function([key, value]) {
              if (value["nick"].toString().toLowerCase().indexOf(searchQuery) > -1) {
                containsSearchEntry = true;
                return false;
              }
              return true;
            }
		  );
		  
          if (containsSearchEntry) return false;
        }
        return true;
      }
	);

    if (containsSearchEntry) {
		result.push(server_key);
	}
  }
  
  return result;
}

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
