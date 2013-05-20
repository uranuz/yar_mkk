function gotoPage(pageNum) {
	var form = window.document.getElementById("main_form");
	var pageNumInput = window.document.getElementsByName("cur_page_num")[0];
	pageNumInput.value = pageNum;
	form.submit();
} 
