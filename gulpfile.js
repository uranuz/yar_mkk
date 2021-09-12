'use strict';

var
	path = require('path'),
	tfConfig = require('../trifle/builder/config'),
	tfBuilder = require('../trifle/builder/builder');

function makeConfig() {
	var config = tfConfig.resolveConfig();

	// This gulp script runs scripts for all sites in repository
	config.dependGulpFiles = [
		path.resolve('./client/mkk.gulpfile.js')
	];

	return config;
}

Object.assign(exports, {
	default: tfBuilder.makeTasks(makeConfig())
});
