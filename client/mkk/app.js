require.config({
	waitSeconds: 120,
	baseUrl: "/pub"
});

define('mkk/app', [
	"fir/controls/ControlManager",
	"fir/common/globals",
	"fir/common/helpers",
	"fir/common/text_encoder",
	"fir/common/base64",
	"fir/network/json_rpc",
	"fir/datctrl/helpers",
	"fir/datctrl/EnumFormat",
	"fir/datctrl/RecordFormat",
	"fir/datctrl/Record",
	"fir/datctrl/RecordSet",
	"fir/controls/CheckBoxList/CheckBoxList",
	"fir/controls/PlainListBox/PlainListBox",
	"fir/controls/PlainDatePicker/PlainDatePicker",
	"css!mkk/app"
], function(ControlManager) {
	ControlManager.launchMarkup($('body'));
});
require(['mkk/app'], function() {});