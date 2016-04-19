module.exports = function (grunt) {
	'use strict';
	
	// Force use of Unix newlines
	grunt.util.linefeed = '\n';
	
	var mq4HoverShim = require('mq4-hover-shim');
	var autoprefixer = require('autoprefixer')({
		browsers: [
			//
			// Official browser support policy:
			// http://v4-alpha.getbootstrap.com/getting-started/browsers-devices/#supported-browsers
			//
			'Chrome >= 35', // Exact version number here is kinda arbitrary
			// Rather than using Autoprefixer's native "Firefox ESR" version specifier string,
			// we deliberately hardcode the number. This is to avoid unwittingly severely breaking the previous ESR in the event that:
			// (a) we happen to ship a new Bootstrap release soon after the release of a new ESR,
			//     such that folks haven't yet had a reasonable amount of time to upgrade; and
			// (b) the new ESR has unprefixed CSS properties/values whose absence would severely break webpages
			//     (e.g. `box-sizing`, as opposed to `background: linear-gradient(...)`).
			//     Since they've been unprefixed, Autoprefixer will stop prefixing them,
			//     thus causing them to not work in the previous ESR (where the prefixes were required).
			'Firefox >= 31', // Current Firefox Extended Support Release (ESR)
			// Note: Edge versions in Autoprefixer & Can I Use refer to the EdgeHTML rendering engine version,
			// NOT the Edge app version shown in Edge's "About" screen.
			// For example, at the time of writing, Edge 20 on an up-to-date system uses EdgeHTML 12.
			// See also https://github.com/Fyrd/caniuse/issues/1928
			'Edge >= 12',
			'Explorer >= 9',
			// Out of leniency, we prefix these 1 version further back than the official policy.
			'iOS >= 8',
			'Safari >= 8',
			// The following remain NOT officially supported, but we're lenient and include their prefixes to avoid severely breaking in them.
			'Android 2.3',
			'Android >= 4',
			'Opera >= 12'
		]
	});

	grunt.initConfig({
		watch: {
			sass: {
				files: 'scss/**/*.scss',
				tasks: ['dist-css']
			}
		},
		
		sass: {
			options: {
				includePaths: ['scss', 'node_modules/bootstrap/scss'],
				precision: 6,
				sourceComments: false,
				sourceMap: true,
				outputStyle: 'expanded'
			},
			core: {
				files: {
					'dist/css/app.css': 'scss/app.scss'
				}
			}
		},
		
		/*
		// CSS build configuration
		scsslint: {
			options: {
				bundleExec: true,
				config: 'scss/.scss-lint.yml',
				reporterOutput: null
			},
			src: ['scss/*.scss', '!scss/_normalize.scss']
		},
		*/

		postcss: {
			core: {
				options: {
					map: true,
					processors: [
						mq4HoverShim.postprocessorFor({ hoverSelectorPrefix: '.bs-true-hover ' }),
						autoprefixer
					]
				},
				src: 'dist/css/*.css'
			}
		},

		cssmin: {
			options: {
				// TODO: disable `zeroUnits` optimization once clean-css 3.2 is released
				//    and then simplify the fix for https://github.com/twbs/bootstrap/issues/14837 accordingly
				compatibility: 'ie9',
				keepSpecialComments: '*',
				sourceMap: true,
				advanced: false
			},
			core: {
				files: [
					{
						expand: true,
						cwd: 'dist/css',
						src: ['*.css', '!*.min.css'],
						dest: 'dist/css',
						ext: '.min.css'
					}
				]
			}
		},

		csscomb: {
			options: {
				config: 'csscomb.json'
			},
			dist: {
				expand: true,
				cwd: 'dist/css/',
				src: ['*.css', '!*.min.css'],
				dest: 'dist/css/'
			}
		},
		
		copy: {
			js: {
				expand: true,
				cwd: 'node_modules/bootstrap/dist/',
				src: [
					'js/**/*'
				],
				dest: '../pub/bootstrap/'
			},
			css: {
				expand: true,
				cwd: 'dist',
				src: [
					'css/**/*'
				],
				dest: '../pub/bootstrap/'
			}
		}
	});
	
	// These plugins provide necessary tasks.
	require('load-grunt-tasks')(grunt);
	require('time-grunt')(grunt);
	
	grunt.registerTask('sass-compile', ['sass:core']);
	grunt.registerTask('dist-css', ['sass-compile', 'postcss:core', 'csscomb:dist', 'cssmin:core', 'copy:js', 'copy:css' ]);
}