'use strict';
var perf = {
	nl: String.fromCharCode(10),
	crlf: String.fromCharCode(10) + String.fromCharCode(13),
	i18n: function(key, _default){
		key = key.toLowerCase();
		if (perf.langBundle[key]){
			return perf.langBundle[key];
		} else {
			console.warn("missing language string: [" + key + "] for locale: [" + perf.locale + "] from javascript");
			if (_default)
				return _default;
			else
				return key;
		}
	},
	langBundle: {},
	locale: "en",
	importi18n: function(pluginLanguage){
		for (var str in pluginLanguage.STRINGS)
			perf.langBundle[(String(str).toLowerCase())] = pluginLanguage.STRINGS[str];
		perf.locale = pluginLanguage.locale;
    },	
    sortTable:		function (th, sortDefault){					
		var tr = th.parentElement;
		var table = tr.parentElement.parentElement; // table;
		var tbodys = table.getElementsByTagName("tbody");
		var theads = table.getElementsByTagName("thead");
		var rowspans = (table.dataset.rowspan !== "false");

		if (!th.dataset.type)
			th.dataset.type = sortDefault; // otherwise text
		if (!th.dataset.dir){
			th.dataset.dir = "asc";
		} else {
			if (th.dataset.dir == "desc")
				th.dataset.dir = "asc";
			else
				th.dataset.dir = "desc";
		}
		for (var h = 0; h < tr.children.length; h++){
			var cell = tr.children[h].style;
			if (h === th.cellIndex){
				cell.fontWeight = 700;
				cell.fontStyle = (th.dataset.dir == "desc") ? "normal" : "italic";
			} else {
				cell.fontWeight = 300;
				cell.fontStyle = "normal";
			}
		}
		var sortGroup = false;
		var localeCompare = "test".localeCompare ? true : false;
		var numberParser = new Intl.NumberFormat('en-US');
		var data = [];

		for ( var b = 0; b < tbodys.length; b++ ){
			var tbody =tbodys[b];
			for ( var r = 0; r < tbody.children.length; r++ ){
				var row = tbody.children[r];
				var group = false;
				if (row.classList.length > 0){
					// check for class sort-group
					group = row.classList.contains("sort-group");
				}
				// this is to handle secondary rows with rowspans, but this stops two column tables from sorting
				if (group){
					data[data.length-1][1].push(row);
				} else {
					switch (row.childElementCount){
						case 0:
						case 1:
							continue;
						case 2:
							if (!rowspans)
								break;
							if (data.length > 1)
								data[data.length-1][1].push(row);										
							continue;
						default:
							break;
					}								
					var cell = row.children[th.cellIndex];
					var val = cell.innerText;
					if (!localeCompare){
						switch (th.dataset.type){
							case "text":
								val = val.toLowerCase();
								break;
							case "numeric":
							case "number":
								switch (val){
									case "":
									case "-":
										val = -1;
										break;
									default:
										val = Number(val);
									break;
								}
								break;
						}
					} else {
						// hack to handle formatted numbers with commas for thousand separtors
						var tmpNum = val.split(",");
						if (tmpNum.length > 1){
							tmpNum = Number(tmpNum.join(""));
							if (tmpNum !== NaN)
								val = String(tmpNum);
						}
					}
					var _row = row;
					if (r === 0 && 
							theads.length > 1 &&
							tbody.previousElementSibling.nodeName === "THEAD" && 
							tbody.previousElementSibling.children.length){
						data.push([val, [tbody.previousElementSibling, row], tbody]);
						sortGroup = true;
					} else {
						data.push([val, [row]]);
					}
					
				}
			}
		}

		switch (th.dataset.type){
			case "text":
				data = data.sort(function(a,b){
					if (localeCompare){
						return a[0].localeCompare(b[0],"en", {numeric:true, ignorePunctuation: true});
					} else {
						if (a[0] < b[0])
							return -1;
						if (a[0] > b[0])
							return 1;
						return 0;
					}                    
				});
				break;
			case "numeric": 
			case "number":
				data = data.sort(function(a,b){
					return a[0] - b[0];
				}); 
		}
		
		if (th.dataset.dir === "asc")
			data.reverse();
		if (!sortGroup){
			for (r = 0; r < data.length; r++){
				for (var rr = 0; rr < data[r][1].length; rr++)
					tbody.appendChild(data[r][1][rr]);
			}						
		} else {
			for (r = 0; r < data.length; r++){
			
				if (data[r].length === 3){
					var _rows = data[r];
					table.appendChild(_rows[1][0]); // thead
					table.appendChild(_rows[2]); // tbody
					var _tbody = _rows[2];
					for (var rr = 1; rr < _rows[1].length; rr++)
						_tbody.appendChild(_rows[1][rr]); // tr
					
				} else {
					for (var rr = 0; rr < data[r][1].length; rr++)
						table.appendChild(data[r][1][rr]); 
				}
			}
		}

	}
};

$(function(){
	if (!pluginLanguage)
		console.warn("pluginLanguage missing, use #renderUtils.includeLang()#");
	else
		perf.importi18n(pluginLanguage);

	$(".sort-table TH").on("click", perf.sortTable);	
});
