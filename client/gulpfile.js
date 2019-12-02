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
	gulpClean = require('gulp-clean');

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
		config.publicPath = '/pub/';
		config.outSite = path.resolve(outSites, site);
		config.outPub = path.resolve(
			config.outSite,
			config.publicPath.replace(/^\//, '') // Trim leading slash
		);
		config.outTemplates = path.resolve(config.outSite, 'res/templates');
	}
})();


var bootstrapSass = path.resolve(__dirname, '../node_modules/bootstrap/scss');


function buildEntry(config, entry, callback) {
	var
		entryMap = {},
		libraryTarget = 'var',
		manifestsPath = path.join(config.outPub, `manifest/`),
		library = (entry === 'mkk/app'? 'mkk_app': 'mkk_lib'); // entry.split('/').join('_'), // Replacing slashes with underscores;
	entryMap[entry] = [entry];
	
	// run webpack
	webpack({
		context: __dirname,
		mode: (devMode? 'development': 'production'),
		entry: entryMap,
		/*
		externals: [
			nodeExternals(),
			
			// /^fir\//,
			// /^ivy\//,
			function(basePath, moduleName, callback) {
				if( /^(fir|ivy)\//.test(moduleName) ) {
					return callback(null, 'arguments[2]("./' + moduleName + '.js")');
				}
				callback();
			}
			
		],
		*/
		resolve: {
			modules: [
				__dirname,
				path.resolve(__dirname, '../../', 'fir'),
				path.resolve(__dirname, '../../', 'ivy')
			],
			alias: {
				'../../fir': './fir',
				'../../ivy': './ivy',
			},
			extensions: ['.js', '.scss']
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
								implementation: require('node-sass'),
								sourceMap: true,
								sassOptions: {
									indentWidth: 4,
									includePaths: [bootstrapSass, __dirname],
								}
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
								name: '[path][name].[ext]',
								publicPath: config.publicPath
							}
						}
					]
				}
			]
		},
		plugins: [
			new webpack.DllReferencePlugin({
				context: '', //path.resolve(__dirname, '../../ivy'),
				manifest: require(path.join(manifestsPath, 'ivy.manifest.json')),
				sourceType: libraryTarget
			}),
			new webpack.DllReferencePlugin({
				context: '', //path.resolve(__dirname, '../../fir'),
				manifest: require(path.join(manifestsPath, 'fir.manifest.json')),
				sourceType: libraryTarget
			}),
			new webpack.DllPlugin({
				name: library,
				path: path.join(manifestsPath, entry + '.manifest.json')
			}),
			new MiniCssExtractPlugin({
				// Options similar to the same options in webpackOptions.output
				// both options are optional
				filename: (devMode ? '[name].css' : '[name].[hash].css'),
				chunkFilename: (devMode ? '[id].css' : '[id].[hash].css'),
			})
		],
		/*
		optimization: {
			runtimeChunk: {
				name: "manifest",
			}
		},
		*/
		devtool: 'cheap-source-map',
		output: {
			path: config.outPub,
			publicPath: config.publicPath,
			filename: entry + '.js',
			libraryTarget: libraryTarget,
			library: library
		}
	}, callback);
}

function buildSite(config, callback) {
	var counter = config.entry.length;

	config.entry.forEach(function(it) {
		buildEntry(config, it, function(err, stats) {
			if(err) {
				throw new gutil.PluginError("webpack", err);
			}
			gutil.log("[webpack]", stats.toString({
				// output options
			}));
			counter--;
			if( counter <= 0 ) {
				callback(); // сообщаем gulp'у, что точки входа собраны
			}
		});
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
	return gulp.src(['mkk/**/*.js'], {
			base: './'
		})
		.pipe(gulp.symlink(sites.mkk.outPub, {
			owerwrite: false // Don't overwrite files generated by webpack
		}));
});

gulp.task("mkk-symlink-files", function() {
	return gulp.src([
			'flot',
			'reports',
			'stati_dokument',
			'ext',
			'robots.txt',
			'mkk/run_globals.js',
			'mkk/run_app.js'
		], {base: './'})
		.pipe(vfs.symlink(sites.mkk.outPub));
});

gulp.task("mkk-symlink-bootstrap", function() {
	return gulp.src([
			'../node_modules/bootstrap/dist/**/*.js'
		], {base: '../node_modules/'})
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

gulp.task("mkk-clean", function() {
	return gulp.src([sites.mkk.outPub, sites.mkk.outTemplates], {
		read: false,
		allowEmpty: true
	}).pipe(gulpClean({force: true}));
});

// Create bundles then add nonexisting files as symlinks...
gulp.task("mkk-js", gulp.series(["mkk-webpack", "mkk-symlink-js"]))

gulp.task("mkk", gulp.series([
	"mkk-clean",
	"mkk-ivy",
	"mkk-fir",
	"mkk-webpack",
	"mkk-symlink-templates",
	"mkk-symlink-files",
	"mkk-symlink-bootstrap"
]));

/*** FILMS tasks */
gulp.task("films-webpack", function(callback) {
	buildSite(sites.films, callback);
});

gulp.task("films", gulp.series(["films-webpack"]));


gulp.task("default", gulp.series(['mkk']));

