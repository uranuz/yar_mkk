module.exports = function (grunt) {
	'use strict';

	// Force use of Unix newlines
	grunt.util.linefeed = '\n';
	var
		expandTilde = require('expand-tilde'),
		sass = require('node-sass');

	var entryPoints = [
		"mkk/require",
		"mkk/require-css",
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
	], rJSBuildConfig = {
		options: {
			baseUrl: "./client/",
			removeCombined: true,
			mainConfigFile: "./client/mkk/app.js",
			findNestedDependencies: true,
			fileExclusionRegExp: /^(?!(?:.+\.js|[^.]*|\.\.)$)/, // Хотим только js файлы. Условие [^.]* для папок
			paths: {
				fir: "../../fir",
				ivy: "../../ivy/ivy"
			},
			map: {
				"*": {
					'css': 'mkk/scss-builder'
				}
			},
			separateCSS: true,
			onBuildRead: function (moduleName, path, contents) {
				if( this.name.startsWith('mkk/app') ) {
					return contents;
				}
				if (moduleName.startsWith('fir/') || moduleName.startsWith('ivy/') ) {
					return ''; // Exclude library modules via dropping it's contents
				}
				return contents;
			},
			exclude: [
				'mkk/normalize',
				'mkk/scss-builder'
			],
			skipModuleInsertion: true // Don't want empty modules to be put
		}
	},
	cleanPathsBase = {
		bootstrap: '<%= deployPath %>pub/bootstrap/**/*',
		jquery: '<%= deployPath %>pub/jquery-2.2.4.min.js',
		jqueryCookie: '<%= deployPath %>pub/jquery.cookie-1.4.1.min.js',
		jqueryui: '<%= deployPath %>pub/jquery-ui-1.12.1.custom/**/*',
		popper: '<%= deployPath %>pub/popper-1.12.5.min.js',
	}
	// Extra object for making clean configuration less verbose
	cleanPaths = {
		templates: '<%= deployPath %>res/templates/mkk/**/*.ivy',
		templates_films: '<%= deployPath %>res/templates/films/**/*.ivy',
		scripts: '<%= deployPath %>pub/mkk/**/*.js',
		styles: '<%= deployPath %>pub/mkk/**/*.css',
		imgFolder: '<%= deployPath %>pub/mkk/img',
		stati_dokument: '<%= deployPath %>pub/stati_dokument',
		reports: '<%= deployPath %>pub/reports',
		robots: '<%= deployPath %>pub/robots.txt',
		reports: '<%= deployPath %>pub/flot'
	},
	cleanConfig = {},
	symlink_base = {
		bootstrap: {
			expand: true,
			cwd: 'node_modules/bootstrap/dist/',
			src: './**/*.js',
			dest: '<%= deployPath %>pub/bootstrap/',
			filter: 'isFile',
			overwrite: true
		},
		jquery: {
			src: 'client/jquery-2.2.4.min.js',
			dest: '<%= deployPath %>pub/jquery-2.2.4.min.js',
			filter: 'isFile'
		},
		jqueryCookie: {
			src: 'client/jquery.cookie-1.4.1.min.js',
			dest: '<%= deployPath %>pub/jquery.cookie-1.4.1.min.js',
			filter: 'isFile'
		},
		jqueryui: {
			expand: true,
			cwd: 'client/jquery-ui-1.12.1.custom/',
			src: './**/*.*',
			dest: '<%= deployPath %>pub/jquery-ui-1.12.1.custom/',
			filter: 'isFile',
			overwrite: true
		},
		popper: {
			src: 'client/popper-1.12.5.min.js',
			dest: '<%= deployPath %>pub/popper-1.12.5.min.js',
			filter: 'isFile'
		}
	},
	symlink = {
		templates: {
			expand: true,
			cwd: 'client/mkk',
			src: './**/*.ivy',
			dest: '<%= deployPath %>res/templates/mkk/',
			filter: 'isFile',
			overwrite: true
		},
		templates_films: {
			expand: true,
			cwd: 'client/films',
			src: './**/*.ivy',
			dest: '<%= deployPath %>res/templates/films/',
			filter: 'isFile',
			overwrite: true
		},
		scripts: {
			expand: true,
			cwd: 'client/mkk',
			src: './**/*.js',
			dest: '<%= deployPath %>pub/mkk/',
			filter: 'isFile',
			overwrite: true
		},
		scripts_films: {
			expand: true,
			cwd: 'client/films',
			src: './**/*.js',
			dest: '<%= deployPath %>pub/films/',
			filter: 'isFile',
			overwrite: true
		},
		imgFolder: {
			src: 'client/mkk/img',
			dest: '<%= deployPath %>pub/mkk/img',
			filter: 'isDirectory'
		},
		stati_dokument: {
			src: 'client/stati_dokument/',
			dest: '<%= deployPath %>pub/stati_dokument',
			filter: 'isDirectory'
		},
		reports: {
			src: 'client/reports/',
			dest: '<%= deployPath %>pub/reports',
			filter: 'isDirectory'
		},
		robots: {
			src: 'client/robots.txt',
			dest: '<%= deployPath %>pub/robots.txt',
			filter: 'isFile'
		},
		flot: {
			src: 'client/flot/',
			dest: '<%= deployPath %>pub/flot',
			filter: 'isDirectory'
		}
	},
	sass = {
		options: {
			includePaths: [
				'client/bootstrap/scss',
				'node_modules/bootstrap/scss'
			],
			precision: 6,
			sourceComments: false,
			sourceMap: true,
			outputStyle: 'expanded',
			// Обход бага: https://github.com/sourcey/spectacle/issues/156
			implementation: sass
		},
		mkk: {
			files: [
				{
					expand: true,
					cwd: 'client/mkk',
					src: ['./**/*.scss'],
					dest: '<%= deployPath %>pub/mkk/',
					ext: '.css',
					overwrite: true
				}
			]
		},
		films: {
			files: [
				{
					expand: true,
					cwd: 'client/films',
					src: ['./**/*.scss'],
					dest: '<%= deployPath %>pub/films/',
					ext: '.css',
					overwrite: true
				}
			]
		}
	},
	sites = ['mkk', 'films'];

	var path = require('path');

	entryPoints.forEach(function(moduleName) {
		rJSBuildConfig[moduleName] = {
			options: {
				name: moduleName,
				out: "<%= deployPath %>pub/" + moduleName + ".js",
				siteRoot: __dirname + "/client/" + path.dirname(moduleName) // Hack for resolving URLs in CSS
			}
		}
	});

	for( var key in cleanPaths ) {
		if( cleanPaths.hasOwnProperty(key) ) {
			cleanConfig[key] = {
				options: { force: true },
				files: { src: cleanPaths[key] }
			}
		}
	}

	for( var i = 0; i < sites.length; ++i ) {
		var site = sites[i];
		for( var name in symlink_base ) {
			if( !symlink_base.hasOwnProperty(name) ) {
				continue;
			}
			symlink[name + '_' + site] = symlink_base[name];
		}

		for( var name in cleanPathsBase ) {
			if( !cleanPathsBase.hasOwnProperty(name) ) {
				continue;
			}
			cleanPaths[name + '_' + site] = cleanPathsBase[name];
		}
		
		sass.bootstrap = {
			files: [
				{
					src: 'client/bootstrap/scss/app.scss',
					dest: '<%= deployPath %>pub/bootstrap/css/app.css'
				}
			]
		}
	}

	grunt.initConfig({
		deployPath: (function() {
			// Используем путь для разворота, указанный у сервиса представления,
			// чтобы каждый раз явно не указывать его в консоли
			var config = {};
			if( grunt.file.exists('services_config.json') ) {
				config = grunt.file.readJSON('services_config.json');
			}
			return expandTilde(config.services.yarMKKView.fileSystemPaths.siteRoot);
		})(),

		symlink: symlink,
		sass: sass,
		clean: cleanConfig,
		requirejs: rJSBuildConfig,
		watch: {
			sass: {
				files: ['client/mkk/**/*.scss'],
				tasks: ['sass:mkk'],
				options: {
					spawn: false
				}
			}
		}
	});

	// These plugins provide necessary tasks.
	require('load-grunt-tasks')(grunt);
	require('time-grunt')(grunt);

	grunt.loadNpmTasks('grunt-contrib-watch');
	grunt.loadNpmTasks('grunt-contrib-symlink');
	grunt.loadNpmTasks('grunt-sass');
	grunt.loadNpmTasks('grunt-contrib-clean');
	grunt.loadNpmTasks('grunt-contrib-requirejs');

	grunt.registerTask('cleanAll', ['clean']);
	grunt.registerTask('deploy', [
		'cleanAll',
		'symlink',
		'sass:bootstrap',
		'sass:mkk'
	]);
	grunt.registerTask('default', ['deploy']);
	grunt.registerTask('dist', [
		'cleanAll',
		'symlink',
		'sass:bootstrap',
		'requirejs'
	]);
}
