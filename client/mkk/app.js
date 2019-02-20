require.config({
	waitSeconds: 120,
	baseUrl: "/pub"
});

define('mkk/app', [
	"fir/controls/Loader/Manager",
	"fir/controls/Loader/IvyServerFactory",
	"fir/controls/Loader/IvyServerRender",
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
], function(LoaderManager, IvyServerFactory, IvyServerRender, ControlManager) {
	LoaderManager.add(new IvyServerFactory());
	LoaderManager.add(new IvyServerRender());
	ControlManager.launchMarkup($('body'));
});
require(['mkk/app'], function() {});