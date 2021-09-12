'use strict';

var
	path = require('path'),
	tfConfig = require('../../trifle/builder/config'),
	tfBuilder = require('../../trifle/builder/builder'),
	entries = require('./mkk/entries.json');

function makeConfig() {
	var config = tfConfig.resolveConfig();
	// Set paths to clean before run build
	config.cleanPaths = [
		path.join(config.buildPath, 'mkk'),
		path.join(config.buildAuxPath, 'mkk'),
		path.join(config.outPub, 'mkk'),
		path.join(config.outPub, 'ext'),
		path.join(config.outPub, 'flot')
	];

	// Set path to external grunt files that build required libraries
	config.dependGulpFiles = [
		path.resolve('../../fir/gulpfile.js')
	];

	config.symlinkBuildPaths = [
		path.join(__dirname, 'mkk')
	];

	// Set webpack libraries we want to build
	entries.forEach(function(entry) {
		config.webpack.entries[entry] = path.join(config.buildPath, entry);
	});

	// Set external libs we depend on
	config.webpack.extLibs = [
		'ivy',
		'fir'
	];

	config.symlinkPubPaths = [
		path.join(__dirname, 'ext'),
		path.join(__dirname, 'flot')
	];

	config.symlinkTemplatesPaths = [
		path.join(__dirname, 'mkk/**/*.ivy')
	];

	return config;
}

Object.assign(exports, {
	default: tfBuilder.makeTasks(makeConfig())
});