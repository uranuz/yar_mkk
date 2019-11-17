'use strict';

var
	devMode = process.env.NODE_ENV !== 'production',
	path = require('path'),
	gulp = require('gulp'),
	webpack = require('webpack'),
	nodeExternals = require('webpack-node-externals'),
	gutil = require("gulp-util"),
	MiniCssExtractPlugin = require('mini-css-extract-plugin'),
	vfs = require('vinyl-fs'),
	shell = require('gulp-shell'),
	yargs = require('yargs'),
	argv = yargs.argv,
	expandTilde = require('expand-tilde'),
	gulpDebug = require('gulp-debug');

var
	sites = {
		mkk: {
			entry: [
				"bootstrap/app.scss",
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

(function resolveConfig() {
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
		config.outSite = path.resolve(outSites, site);
		config.outPub = path.resolve(config.outSite, 'pub');
		config.outTemplates = path.resolve(config.outSite, 'res/templates');
	}
})();


function buildSite(config, callback) {
	var entryMap = {};

	config.entry.forEach(function(it) {
		entryMap[it] = it;
	});

	// run webpack
	webpack({
		context: __dirname,
		mode: (devMode? 'development': 'production'),
		entry: entryMap,
		externals: [
			nodeExternals(),
			/^fir\//,
			/^ivy\//
		],
		resolve: {
			modules: [
				__dirname
			],
			extensions: ['.js']
		},
		module: {
			rules: [
				{
					test: /\.s[ac]ss$/,
					use: [
						MiniCssExtractPlugin.loader,
						// Translates CSS into CommonJS
						{
							loader: 'css-loader',
							options: {
								sourceMap: true
							}
						},
						// Compiles Sass to CSS
						{
							loader: 'sass-loader',
							options: {
								sourceMap: true
							}
						}
					]
				},
				{
					test: /\.(png|jpe?g|gif|svg)$/,
					use: [
						{
							loader: 'file-loader',
							options: {
								name: '[path][name].[ext]'
							}
						}
					]
				}
			]
		},
		plugins: [
			new MiniCssExtractPlugin({
				// Options similar to the same options in webpackOptions.output
				// both options are optional
				filename: (devMode ? '[name].css' : '[name].[hash].css'),
				chunkFilename: (devMode ? '[id].css' : '[id].[hash].css'),
			})
		],
		optimization: {
			runtimeChunk: {
				name: "manifest",
			}
		},
		devtool: 'cheap-source-map',
		output: {
			path: config.outPub
		}
	}, function(err, stats) {
		if(err) throw new gutil.PluginError("webpack", err);
		//gutil.log("[webpack]", stats.toString({
			// output options
		//}));
		callback();
	});
}

gulp.task("mkk-webpack", function(callback) {
	buildSite(sites.mkk, callback);
});

gulp.task("mkk-symlink-templates", function() {
	return gulp.src(['mkk/**/*.ivy'], {base: './'})
		.pipe(vfs.symlink(sites.mkk.outTemplates));
});

gulp.task("mkk-symlink-js", function() {
	return gulp.src(['mkk/**/*.js'], {base: './'})
		/*
		.pipe(gulpDebug({
			showFiles: true,
			minimal: false
		}))
		*/
		.pipe(gulp.symlink(sites.mkk.outPub));
});

gulp.task("mkk-symlink-files", function() {
	return gulp.src([
			'flot',
			'reports',
			'stati_dokument',
			'ext',
			'robots.txt'
		], {base: './'})
		.pipe(vfs.symlink(sites.mkk.outPub));
});

gulp.task("mkk-ivy", shell.task(
	'gulp --outPub=' + sites.mkk.outPub,
	{
		cwd: path.resolve('../../ivy/') // Set current working dir
	}
));

gulp.task("mkk-fir", shell.task(
	'gulp --outPub=' + sites.mkk.outPub + ' --outTemplates=' + sites.mkk.outTemplates,
	{
		cwd: path.resolve('../../fir/') // Set current working dir
	}
));

gulp.task("mkk", gulp.parallel([
	"mkk-webpack",
	"mkk-ivy",
	"mkk-fir",
	"mkk-symlink-templates",
	"mkk-symlink-files"
]));

/*** FILMS tasks */
gulp.task("films-webpack", function(callback) {
	buildSite(sites.films, callback);
});

gulp.task("films", gulp.parallel(["films-webpack"]));


gulp.task("default", gulp.parallel(['mkk', 'films']));

