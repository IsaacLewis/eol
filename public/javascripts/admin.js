if(!EOL) var EOL = {};
if(!EOL.Admin) EOL.Admin = {};

EOL.Admin.Behaviors = {
  'select#content_pages_id:change': function(e) {
    page_id=this.options[this.selectedIndex].value;
    new Ajax.Request('/administrator/content_page/get_page_content/'+ page_id,
    {asynchronous:true,
      evalScripts:true,
      onComplete:function(request){hideAjaxIndicator();},
      onLoading:function(request){showAjaxIndicator();}
      });
    return false;
  },

  'form#page_form input#preview:click': function(e) {
		$('page_form').target="_blank";
		$('page_form').action='/administrator/content_page/preview/'+this.form.readAttribute('data-page_id');
		$('page_form').submit();
  },

  'form#page_form input#publish:click': function(e) {
		$('page_form').target="_self";
		$('page_form').action='/administrator/content_page/update/'+this.form.readAttribute('data-page_id');
		$('page_form').submit();
  },

  'select#content_page_archive_id:change': function(e) {
		content_page_archive_id=this.options[this.selectedIndex].value;
		if (content_page_archive_id != '') {
			new Ajax.Request('/administrator/content_page/get_archived_page', {
				asynchronous: true,
				evalScripts: true,
				method: 'post',
				onComplete: function(request){
					hideAjaxIndicator();
          EOL.reload_behaviors();
				},
				onLoading: function(request){
					showAjaxIndicator();
				},
				parameters: 'content_page_archive_id=' + content_page_archive_id + '&content_page_id=' + this.form.readAttribute('data-page_id')
			});
		}
  }
};