// TODO:
// - search again after updating server list
const keysToSkip = [
    "d0id",
    "status",
    "stats",
    "maxspectators",
    "retries",
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
    "players"
];


let isBusy = false;
let serverResp = {};
let searchResults = [];
let currentOffset = 0;
let maxPerPage;

$(document).ready(function() {
    maxPerPage = Math.ceil($(window).height() / 74); // FIXME: hardcoded!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    update();

    $("#filter").on("keyup search", function() {
        if (isBusy) {
			return;
		}
        isBusy = true;

		window.scrollTo(0, 0);

        let searchQuery = $(this).val().toLowerCase();
		if (typeof searchQuery === 'undefined')
			searchQuery = "";
        searchResults = search(searchQuery);
        if (searchResults.length == 0) {
            $("tbody").empty();
            $("tbody").append("<span>No servers found.</span>");
        } else {
            renderTable(searchResults);
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
            } else {
                console.error(request.statusText);
                isBusy = false;
            }
        }
    };
    request.onerror = function(e) {
        let message = "Error " + request.responseText + ": " + request.statusText;
        alert(message);
        console.error(message);
        isBusy = false;
    };
    request.send(null);
}

function renderTable(serverList, offset = 0) {
	if (typeof offset === 0) {
		$("tbody").empty();
		currentOffset = 0;
	}
	
    let counter = 0;
    let appendString = "";
	serverList.every(function(serverKey) {
		console.log(counter + " " + (offset + maxPerPage));
		if (counter < offset) {
			counter++;
			return true;
		} else if (counter >= offset + maxPerPage) {
			return false;
		}
        let server = serverResp["server"][serverKey];
        let numplayers = server["numplayers"];
        let serverenc = server["serverenc"];
        appendString += `<tr data-id="${server["address"]}" class="stripe ${(server["numplayers"] < 1) ? ("hidden empty") : ""} info">` +
            `<td><span class="flag ${"flag-" + server["geo"].toLowerCase()}" title="${server["geo"]}"></span></td>` +
            `<td>${(numplayers > 0) ? "<strong>" + server["realname"] + "</strong>" : server["realname"]}</td>` +
            `<td style="text-align:center;">${server["mode"]}<br><span style="font-size:0.65em;">(${server["mode2"] + (server["impure"] == 0) ? "+PURE" : ""})</span></td>` +
            `<td style="font-size:0.8em;">${server["map"]}</td>` +
            `<td>${(numplayers > 0) ? "<strong>" + server["numplayers"] + "</strong>" : server["numplayers"]}<span style="font-size:0.65em;">/${server["maxplayers"]}</span></td>` +
            `<td><button class="button button-small clipboard" data-clipboard-text="connect ${server["address"]}" title="Copy console connect command to clipboard (Use CTRL+V in the Xonotic console and hit return to connect)">&#x1f517;</button></td>` +
            `<td><button class="button-primary" data-id="${server["address"]}" onclick="buttonClick(event)">Details</button></td>` +
            `</td>`;
        let teamTable = '';
        if (numplayers > 0) {
            teamTable = '<tbody>' +
                //`[% i_sorted = i.teamplay ? i.player.values.nsort('team', 'score').reverse : i.player.values.nsort('score').reverse %]`
                //[% FOREACH p IN i_sorted %]
                //<tr[% IF i.teamplay %] [% IF p.team == 1 %]style="color: red;"[% ELSIF p.team == 2 %]class="bls" style="color: blue;"[% ELSIF p.team == 3 %]class="yes" style="color: yellow;"[% ELSIF p.team == 4 %]class="fus" style="color: fuchsia;"[% END %][% END %]>
                //<td>[% p.nick %]</td>
                //<td style="font-size:0.7em;">[% IF p.ping %][% p.ping %][% ELSE %]bot[% END %]</td>
                //<td>[% IF p.score == -666 %]spec[% ELSE %][% p.score %][% END %]</td>
                //</tr>
                //[% END %]
                //[% END %]
                '</tbody>';
        }
        appendString += `<tr class="hidden stripe details" data-id="${server["address"] + "_details"}">` +
            '<td colspan="7"><div class="five columns"><table class="u-full-width"><thead><tr><th>Server Settings</th><th></th></tr></thead><tbody><tr>' +
            `<td>Address:</td><td><strong>${server["address"]}</strong></td>` +
            '</tr><tr>' +
            `<td>Game Version:</td><td><strong>${server["version"]}</strong></td>` +
            '</tr>' +
            `<tr title="${server["d0id"]}">` +
            `<td>Encryption:</td><td><strong>${(serverenc == 2) ? "Required" : (serverenc == 1) ? "Supported" : "Not Supported"}</strong></td>` +
            '</tr><tr>' +
            `<td>Player Statistics:</td><td><strong>${(server["stats"] == 0) ? "Not Supported" : "Supported"}</strong></td>` +
            '</tr><tr>' +
            `<td>Fullbright Models:</td><td><strong>${(server["fballowed"] == 0) ? "Forbidden" : "Allowed"}</strong></td>` +
            '</tr><tr>' +
            `<td>Impure CVARs:</td><td><strong>${server["impure"]}</strong></td>` +
            '</tr><tr>' +
            `<td>Free Slots:</td><td><strong>${server["slots"]}</strong></td>` +
            '</tr></tbody></table></div><div class="seven columns"><table class="u-full-width"><thead><tr><th>Name</th><th>Ping</th><th>Score</th></tr></thead>' +
            `${teamTable}` +
            '</table>' +
            `${(numplayers == 0 && server["numbots"] == 0) ? "<div><p>No Players.</p></div>" : ""}` +
            '</div></td>';
        counter++;
		return true;
    });
    $("tbody").append(appendString);

    $("button").click((event) => {
        const id = event.target.dataset.id;
        if (id == 'tempty') {
            $('tr.empty').toggle();
            $('.kek').remove();
        } else {
            $('tr[data-id="' + id + '_details"]').toggle();
        }
    });

    isBusy = false;
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
                if (key != "players" && value.toString().toLowerCase().indexOf(searchQuery) > -1) {
                    containsSearchEntry = true;
                    return false;
                }

                if (key == "players") {
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

function buttonClick(event) {
    const id = event.target.dataset.id;
    if (id === 'tempty') {
        $('tr.empty').toggle();
        $('.kek').remove();
    } else {
        $('tr[data-id="' + id + '_details"]').toggle();
    }
}

$(window).on("scroll", function() {
	if (isBusy)
		return;
	
    let scrollHeight = $(document).height();
    let scrollPosition = $(window).height() + $(window).scrollTop();
	let serverLength = Object.keys(serverResp.server).length;
	
    if ((scrollHeight - scrollPosition) / scrollHeight === 0 &&
        serverLength > currentOffset) {
        currentOffset += maxPerPage;
        renderTable(searchResults, currentOffset);
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