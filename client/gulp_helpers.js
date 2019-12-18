var
	devMode = process.env.NODE_ENV !== 'production',
	path = require('path'),
	yargs = require('yargs'),
	argv = yargs.argv,
	expandTilde = require('expand-tilde');

var
	sites = {
		mkk: {
			entry: [
				"bootstrap/scss/app",
				"mkk/Tourist/Experience/Experience",
				"mkk/GeneralTemplate/GeneralTemplate",
				"mkk/IndexPage/IndexPage",
				"mkk/User/ModerList/ModerList",
				"mkk/Pohod/Edit/Edit",
				"mkk/Pohod/List/List",
				"mkk/Pohod/Read/Read",
				"mkk/Tourist/Edit/Edit",
				"mkk/Tourist/List/List",
				"mkk/Document/List/List",
				"mkk/Document/Edit/Edit",
				"mkk/Pohod/Stat/Stat",
				"mkk/User/Settings/Settings",
				"mkk/AboutSite/AboutSite",
				"mkk/RecordHistory/RecordHistory",
				"mkk/Right/List/List",
				"mkk/Right/Object/List/List",
				"mkk/User/Reg/Reg",
				"mkk/User/Reg/Card/Card",
				"mkk/app"
			]
		},
		films: {
			entry: [
				"films/IndexPage/IndexPage"
			]
		}
	};


function resolveConfig() {
	var outSites = argv.outSites;
	if( !outSites ) {
		outSites = expandTilde('~/sites/');
		console.warn('--outSites option is not set so using default path inside user folder: ' + outSites);
	}
	for( var site in sites ) {
		if( !sites.hasOwnProperty(site) ) {
			continue;
		}
		var config = sites[site];
		config.publicPath = '/pub/';
		config.outSite = path.resolve(outSites, site);
		config.outPub = path.resolve(
			config.outSite,
			config.publicPath.replace(/^\//, '') // Trim leading slash
		);
		config.outBuild = path.resolve(config.outSite, 'build');
		config.outTemplates = path.resolve(config.outSite, 'res/templates');
	}
	return sites;
}

module.exports = {
	resolveConfig: resolveConfig,
	CMD_LINE_OPTS: ['outSites']
};