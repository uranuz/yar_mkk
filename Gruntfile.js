module.exports = function (grunt) {
	'use strict';

	// Force use of Unix newlines
	grunt.util.linefeed = '\n';
	var expandTilde = require('expand-tilde');

	var entryPoints = [
		"mkk/require",
		"mkk/require-css",
		"mkk/Experience/Experience",
		"mkk/GeneralTemplate/GeneralTemplate",
		"mkk/IndexPage/IndexPage",
		"mkk/ModerList/ModerList",
		"mkk/PohodEdit/PohodEdit",
		"mkk/PohodList/PohodList",
		"mkk/PohodRead/PohodRead",
		"mkk/TouristEdit/TouristEdit",
		"mkk/TouristList/TouristList",
		"mkk/Stat/Stat",
		"mkk/app"
	], rJSBuildConfig = {
		options: {
			baseUrl: "./client/",
			removeCombined: true,
			mainConfigFile: "./client/mkk/app.js",
			findNestedDependencies: true,
			fileExclusionRegExp: /^(?!(?:.+\.js|[^.]*|\.\.)$)/, // Хотим только js файлы. Условие [^.]* для папок
			paths: {
				fir: "../../fir"
			},
			map: {
				"*": {
					'css': 'mkk/scss-builder'
				}
			},
			separateCSS: true,
			onBuildRead: function (moduleName, path, contents) {
				if (moduleName.startsWith('fir/') && !this.name.startsWith('mkk/app')) {
					return ''; // Exclude library modules via dropping it's contents
				} else {
					return contents;	
				}
			},
			exclude: [
				'mkk/normalize',
				'mkk/scss-builder'
			],
			skipModuleInsertion: true // Don't want empty modules to be put
		}
	},
	// Extra object for making clean configuration less verbose
	cleanPaths = {
		templates: '<%= deployPath %>res/templates/mkk/**/*.ivy',
		scripts: '<%= deployPath %>pub/mkk/**/*.js',
		styles: '<%= deployPath %>pub/mkk/**/*.css',
		imgFolder: '<%= deployPath %>pub/mkk/img',
		stati_dokument: '<%= deployPath %>pub/stati_dokument',
		reports: '<%= deployPath %>pub/reports',
		robots: '<%= deployPath %>pub/robots.txt',
		bootstrap: '<%= deployPath %>pub/bootstrap/**/*',
		jqueryui: '<%= deployPath %>pub/jquery-ui-1.12.1.custom/**/*',
		flot: '<%= deployPath %>/pub/flot/**/*'
	},
	cleanConfig = {};

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

	grunt.initConfig({
		deployPath: (function() {
			// Используем путь к для разворота, указанный у сервиса представления,
			// чтобы каждый раз явно не указывать его в консоли
			var config = {};
			if( grunt.file.exists('mkk_site_config.json') ) {
				config = grunt.file.readJSON('mkk_site_config.json');
			}
			return expandTilde(config.services.yarMKKView.fileSystemPaths.siteRoot);
		})(),

		symlink: {
			templates: {
				expand: true,
				cwd: 'client/mkk',
				src: './**/*.ivy',
				dest: '<%= deployPath %>res/templates/mkk/',
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
			imgFolder: {
				src: 'client/mkk/img',
				dest: '<%= deployPath %>pub/mkk/img',
				filter: 'isDirectory',
			},
			stati_dokument: {
				src: 'client/stati_dokument/',
				dest: '<%= deployPath %>pub/stati_dokument',
				filter: 'isDirectory',
			},
			reports: {
				src: 'client/reports/',
				dest: '<%= deployPath %>pub/reports',
				filter: 'isDirectory',
			},
			robots: {
				src: 'client/robots.txt',
				dest: '<%= deployPath %>pub/robots.txt',
				filter: 'isFile'
			},
			bootstrap: {
				expand: true,
				cwd: 'node_modules/bootstrap/dist/',
				src: './**/*.js',
				dest: '<%= deployPath %>pub/bootstrap/',
				filter: 'isFile',
				overwrite: true
			},
			jqueryui: {
				expand: true,
				cwd: 'client/jquery-ui-1.12.1.custom/',
				src: './**/*.*',
				dest: '<%= deployPath %>pub/jquery-ui-1.12.1.custom/',
				filter: 'isFile',
				overwrite: true
			},
			flot: {
				expand: true,
				cwd: 'client/flot/',
				src: './**/*.*',
				dest: '<%= deployPath %>/pub/flot/',
				filter: 'isFile',
				overwrite: true
			}
		},
		sass: {
			options: {
				includePaths: [
					'client/bootstrap/scss',
					'node_modules/bootstrap/scss',
				],
				precision: 6,
				sourceComments: false,
				sourceMap: true,
				outputStyle: 'expanded'
			},
			bootstrap: {
				files: [
					{
						src: 'client/bootstrap/scss/app.scss',
						dest: '<%= deployPath %>pub/bootstrap/css/app.css'
					}
				]
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
			}
		},
		clean: cleanConfig,
		requirejs: rJSBuildConfig,
		watch: {
			sass: {
				files: ['client/mkk/**/*.scss'],
				tasks: ['sass:mkk'],
				options: {
					spawn: false,
				},
			},
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
		'symlink:templates',
		'symlink:imgFolder',
		'symlink:stati_dokument',
		'symlink:reports',
		'symlink:robots',
		'symlink:bootstrap',
		'symlink:jqueryui',
		'symlink:flot',
		'sass:bootstrap',
		'requirejs'
	]);
}
