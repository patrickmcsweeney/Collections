function tabclick(e){ 

	if(this.hasClassName("selected")){ return; }
	$$("ul.ep_cs_tab_bar li").each(function(el){ el.removeClassName("selected");  });
	this.addClassName("selected");

	$$("div.ep_cs_tab_panel").each(function(el){ el.hide();  });
	$(this.id+"_content").show();
}

document.observe("dom:loaded", function() {
	$$("input.ep_cs_checkbox").each(function(el){el.observe("click", checkboxClick );});
});

function checkboxClick(e){
	if(this.checked == true){
		$A(document.getElementsByName(this.name)).each(function(el){el.checked=true;});

		var current_time = new Date().getTime();
		var eprinttoadd = this.name.replace(/_add_/,"");
		var url = rel_path+"/cgi/users/collection_select?action=add&collection_eprintid="+$("collection_eprintid").value + "&eprinttoadd=" + eprinttoadd + "&fieldname=" + $("fieldname").value + "&time=" + current_time;
	
		new Ajax.Request(url, {
			method: 'get',
			onSuccess: function(transport) {
				$("selected_eprints").replace(transport.responseText);
				$$("input.ep_cs_checkbox").each(function(el){el.observe("click", checkboxClick );});
			}
		});


	}else{
		$A(document.getElementsByName(this.name)).each(function(el){el.checked=false;});
		
		var current_time = new Date().getTime();
		var eprinttoadd = this.name.replace(/_add_/,"");
		var url = rel_path+"/cgi/users/collection_select?action=remove&collection_eprintid="+$("collection_eprintid").value + "&eprinttorem=" + eprinttoadd + "&fieldname=" + $("fieldname").value + "&time=" + current_time;
	
		new Ajax.Request(url, {
			method: 'get',
			onSuccess: function(transport) {
				$("selected_eprints").replace(transport.responseText);
				$$("input.ep_cs_checkbox").each(function(el){el.observe("click", checkboxClick );});
			}
		});
		
	}
}
