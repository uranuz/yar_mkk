'use strict';

var
	devMode = process.env.NODE_ENV !== 'production',
	path = require('path'),
	gulp = require('gulp'),
	webpack = require('webpack'),
	nodeExternals = require('webpack-node-externals'),
	gutil = require("gulp-util"),
	MiniCssExtractPlugin = require('mini-css-extract-plugin'),
	vfs = require('vinyl-fs');

var
	sites = {
		mkk: {
			entry: [
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
			],
			outPub: '/home/uranuz/sites/mkk/new_pub/',
			outTemplates: '/home/uranuz/sites/mkk/new_templates/'
		},
		films: {
			entry: [
				"films/IndexPage/IndexPage"
			],
			outPub: '/home/uranuz/sites/films/new_pub/',
			outTemplates: '/home/uranuz/sites/films/new_templates/'
		}
	};


function buildSite(config, callback) {
	var entryMap = {};

	config.entry.forEach(function(it) {
		entryMap[it] = it;
	});

	// run webpack
	webpack({
		context: path.resolve(__dirname),
		mode: 'production',
		entry: entryMap,
		externals: [
			nodeExternals(),
			/^fir\//,
			/^ivy\//
		],
		resolve: {
			modules: [
				path.resolve(__dirname)
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
						'css-loader',
						// Compiles Sass to CSS
						'sass-loader',
					]
				},
				{
					test: /\.(png|jpe?g|gif|svg)$/,
					use: [
						{
							loader: 'file-loader',
							options: {
								name: '[path][name].[ext]',
								//outputPath: '/home/uranuz/sites/mkk/new_pub/'
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
			namedModules: true
		},
		output: {
			path: config.outPub
		}
	}, function(err, stats) {
		if(err) throw new gutil.PluginError("webpack", err);
		gutil.log("[webpack]", stats.toString({
			// output options
		}));
		callback();
	});
}

gulp.task("mkk-webpack", function(callback) {
	buildSite(sites.mkk, callback);
});

gulp.task("mkk-symlink-templates", function() {
	return gulp.src([
		'mkk/**/*.ivy'
	]).pipe(vfs.symlink(sites.mkk.outTemplates));
});

gulp.task("mkk-symlink-js", function() {
	return gulp.src([
		'mkk/**/*.js'
	]).pipe(vfs.symlink(sites.mkk.outPub));
});

gulp.task("mkk-symlink-files", function() {
	return gulp.src([
		'flot',
		'reports',
		'stati_dokument',
		'jquery-2.2.4.min.js',
		'jquery-2.2.4.min.js',
		'popper-1.12.5.min.js',
		'robots.txt'
	]).pipe(vfs.symlink(sites.mkk.outPub));
});

gulp.task("mkk", gulp.parallel(["mkk-webpack", "mkk-symlink-templates", 'mkk-symlink-files']));

/*** FILMS tasks */
gulp.task("films-webpack", function(callback) {
	buildSite(sites.films, callback);
});

gulp.task("films", gulp.parallel(["films-webpack"]));


gulp.task("default", gulp.parallel(['mkk', 'films']));

