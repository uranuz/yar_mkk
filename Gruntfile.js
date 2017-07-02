 module.exports = function (grunt) {
	'use strict';

	// Force use of Unix newlines
	grunt.util.linefeed = '\n';
	var expandTilde = require('expand-tilde');

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
				dest: '<%= deployPath %>/res/templates/mkk/',
				filter: 'isFile',
				overwrite: true
			},
			scripts: {
				expand: true,
				cwd: 'client/mkk',
				src: './**/*.js',
				dest: '<%= deployPath %>/pub/mkk/',
				filter: 'isFile',
				overwrite: true
			},
			imgFolder: {
				src: 'client/mkk/img',
				dest: '<%= deployPath %>/pub/mkk/img',
				filter: 'isDirectory',
			},
			stati_dokument: {
				src: 'client/stati_dokument/',
				dest: '<%= deployPath %>/pub/stati_dokument',
				filter: 'isDirectory',
			},
			reports: {
				src: 'client/reports/',
				dest: '<%= deployPath %>/pub/reports',
				filter: 'isDirectory',
			},
			robots: {
				src: 'client/robots.txt',
				dest: '<%= deployPath %>/pub/robots.txt',
				filter: 'isFile'
			},
			bootstrap: {
				expand: true,
				cwd: 'node_modules/bootstrap/dist/',
				src: './**/*.js',
				dest: '<%= deployPath %>/pub/bootstrap/',
				filter: 'isFile',
				overwrite: true
			},
			jqueryui: {
				expand: true,
				cwd: 'client/jquery-ui-1.12.1.custom/',
				src: './**/*.*',
				dest: '<%= deployPath %>/pub/jquery-ui-1.12.1.custom/',
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
						dest: '<%= deployPath %>/pub/bootstrap/css/app.css'
					}
				]
			},
			mkk: {
				files: [
					{
						expand: true,
						cwd: 'client/mkk',
						src: ['./**/*.scss'],
						dest: '<%= deployPath %>/pub/mkk/',
						ext: '.css',
						overwrite: true
					}
				]
			}
		},
		clean: {
			templates: {
				options: { force: true },
				files: { src: '<%= deployPath %>/res/templates/mkk/**/*.ivy' }
			},
			scripts: {
				options: { force: true },
				files: { src: '<%= deployPath %>/pub/mkk/**/*.js' }
			},
			styles: {
				options: { force: true },
				files: { src: '<%= deployPath %>/pub/mkk/**/*.css' }
			},
			imgFolder: {
				options: { force: true },
				files: { src: '<%= deployPath %>/pub/mkk/img' }
			},
			stati_dokument: {
				options: { force: true },
				files: { src: '<%= deployPath %>/pub/stati_dokument' }
			},
			reports: {
				options: { force: true },
				files: { src: '<%= deployPath %>/pub/reports' }
			},
			robots: {
				options: { force: true },
				files: { src: '<%= deployPath %>/pub/robots.txt' }
			},
			bootstrap: {
				options: { force: true },
				files: { src: '<%= deployPath %>/pub/bootstrap/**/*' }
			},
			jqueryui: {
				options: { force: true },
				files: { src: '<%= deployPath %>/pub/jquery-ui-1.12.1.custom/**/*' }
			}
		},
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

	grunt.registerTask('cleanAll', ['clean']);
	grunt.registerTask('deploy', [
		'cleanAll',
		'symlink',
		'sass:bootstrap',
		'sass:mkk'
	]);
	grunt.registerTask('default', ['deploy']);
}
