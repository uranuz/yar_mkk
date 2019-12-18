'use strict';

var
	path = require('path'),
	gulp = require('gulp'),
	vfs = require('vinyl-fs'),
	shell = require('gulp-shell'),
	gulpClean = require('gulp-clean'),
	gulpCopy = require('gulp-copy'),
	gulpHelpers = require('./client/gulp_helpers');

var sites = gulpHelpers.resolveConfig();


gulp.task("mkk-symlink", function() {
	return gulp.src([
			'./client/*'
		], {
			base: './client/',
			ignore: './client/*.gulpfile.js'
		})
		.pipe(vfs.symlink(sites.mkk.outBuild));
});

gulp.task("mkk-copy", function() {
	return gulp.src([
			'./client/mkk.gulpfile.js'
		])
		.pipe(gulp.dest(sites.mkk.outBuild));
});

gulp.task("fir-symlink", function() {
	return gulp.src([
			'../fir/fir/'
		], {base: '../fir/'})
		.pipe(vfs.symlink(sites.mkk.outBuild));
});

// Для gulpfile приходится создавать копию вместо симлинка - иначе не работает. Видимо, баг в gulp-cli или gulp
gulp.task("fir-copy", function() {
	return gulp.src([
			'../fir/fir.gulpfile.js'
		])
		.pipe(gulp.dest(sites.mkk.outBuild));
});

gulp.task("ivy-symlink", function() {
	return gulp.src([
			'../ivy/ivy/'
		], {base: '../ivy/'})
		.pipe(vfs.symlink(sites.mkk.outBuild));
});

gulp.task("ivy-copy", function() {
	return gulp.src([
			'../ivy/ivy.gulpfile.js'
		])
		.pipe(gulp.dest(sites.mkk.outBuild));
});

gulp.task("mkk-node-modules-symlink", function() {
	return gulp.src([
			'node_modules'
		], {base: './'})
		.pipe(vfs.symlink(sites.mkk.outBuild));
});

gulp.task("mkk-clean-build", function() {
	return gulp.src([sites.mkk.outBuild], {
		read: false,
		allowEmpty: true
	}).pipe(gulpClean({force: true}));
});

gulp.task("mkk-symlink-to-build", gulp.parallel([
	'mkk-symlink',
	'mkk-copy',
	'fir-symlink',
	'fir-copy',
	'ivy-symlink',
	'ivy-copy',
	'mkk-node-modules-symlink'
]));

function runBuildOpts(site) {
	var opts = ['gulp'];
	if( !sites.hasOwnProperty(site) ) {
		throw new Error('There is no site "' + site + '" in sites configuration!');
	}
	opts.push('--gulpfile="' + path.resolve(sites[site].outBuild, site + '.gulpfile.js') + '"');
	//opts.push('--cwd="' + path.resolve(sites[site].outBuild, site) + '"');
	var optNames = gulpHelpers.CMD_LINE_OPTS;
	optNames.forEach(function(it) {
		if( site[it] ) {
			opts.push('--' + it + '="' + site[it] + '"');
		}
	});
	return opts.join(' ');
}

gulp.task("mkk-run-build", shell.task(
	runBuildOpts('mkk'),
	{
		cwd: path.resolve(sites.mkk.outBuild) // Set current working dir
	}
));

gulp.task("mkk", gulp.series([
	"mkk-clean-build",
	"mkk-symlink-to-build",
	"mkk-run-build"
]));

gulp.task("default", gulp.series(['mkk']));

