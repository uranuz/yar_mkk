define(['require', './normalize'], function(req, normalize) {
	debugger;
	var scssAPI = {};
	
	var isWindows = !!process.platform.match(/^win/);
	var normalizeWinPath = function(path) {
		return isWindows ? path.replace(/\\/g, '/') : path;
	};
	
	var baseParts = normalizeWinPath(req.toUrl('base_url')).split('/');
	baseParts[baseParts.length - 1] = '';
	var baseUrl = baseParts.join('/');
	
	function compress(css) {
		var csso, csslen;
		if (config.optimizeCss == 'none') {
		return css;
		}
		if (typeof process !== "undefined" && process.versions && !!process.versions.node && require.nodeRequire) {
		try {
			csso = require.nodeRequire('csso');
		}
		catch(e) {
			console.log('Compression module not installed. Use "npm install csso -g" to enable.');
			return css;
		}
		try {
			csslen = css.length;
			if (typeof csso.minify === 'function') {
			css = csso.minify(css).css;
			} else {
			css = csso.justDoIt(css);
			}
			console.log('Compressed CSS output to ' + Math.round(css.length / csslen * 100) + '%.');
			return css;
		}
		catch(e) {
			console.log('Unable to compress css.\n' + e);
			return css;
		}
	
		}
		console.log('Compression not supported outside of nodejs environments.');
		return css;
	}
	function saveFile(path, data) {
		if (typeof process !== "undefined" && process.versions && !!process.versions.node && require.nodeRequire) {
		var fs = require.nodeRequire('fs');
		fs.writeFileSync(path, data, 'utf8');
		}
		else {
		var content = new java.lang.String(data);
		var output = new java.io.BufferedWriter(new java.io.OutputStreamWriter(new java.io.FileOutputStream(path), 'utf-8'));
	
		try {
			output.write(content, 0, content.length());
			output.flush();
		}
		finally {
			output.close();
		}
		}
	}
	
	function escape(content) {
		return content.replace(/(["'\\])/g, '\\$1')
		.replace(/[\f]/g, "\\f")
		.replace(/[\b]/g, "\\b")
		.replace(/[\n]/g, "\\n")
		.replace(/[\t]/g, "\\t")
		.replace(/[\r]/g, "\\r");
	}
	
	var config;
	var siteRoot;
	
	var scss = require.nodeRequire('node-sass');
	var path = require.nodeRequire('path');
	
	var layerBuffer = [];
	var scssBuffer = {};
	
	scssAPI.normalize = function(name, normalize) {
		if (name.substr(name.length - 5, 5) == '.scss')
		name = name.substr(0, name.length - 5);
		return normalize(name);
	};
	
	var absUrlRegEx = /^([^\:\/]+:\/)?\//;
	
	scssAPI.load = function(name, req, load, _config) {
		//store config
		config = config || _config;

		if (!siteRoot) {
			siteRoot = path.resolve(
				config.dir || path.dirname(typeof config.out === 'string' ? config.out : ''),
				config.siteRoot || '.'
			) + '/';
			siteRoot = normalizeWinPath(siteRoot);
		}
	
		if (name.match(absUrlRegEx))
			return load();
	
		var fileUrl = normalizeWinPath(req.toUrl(name + '.scss'));
		var result = scss.renderSync({
			file: fileUrl
		});

		scssBuffer[name] = normalize(String(result.css), siteRoot, fileUrl);
		
		load();
	};
	
	scssAPI.write = function(pluginName, moduleName, write) {
		if (moduleName.match(absUrlRegEx))
		return;
	
		layerBuffer.push(scssBuffer[moduleName]);
	
		//use global variable to combine plugin results with results of require-css plugin
		if (!global._requirejsCssData) {
			global._requirejsCssData = {
				usedBy: {scss: true},
				css: ''
			};
		} else {
			global._requirejsCssData.usedBy.scss = true;
		}

		if (config.name !== moduleName) {
			write.asModule('' + moduleName, 'define(function(){})');
		}
	};
	
	scssAPI.onLayerEnd = function(write, data) {
	
		//calculate layer css
		var css = layerBuffer.join('');
	
		if (config.separateCSS) {
			console.log('Writing  file: ' + data.name + '\n');
		
			var outPath = config.dir ? path.resolve(config.dir, config.baseUrl, data.name + '.css') : config.out.replace(/(\.js)?$/, '.css');
			outPath = normalizeWinPath(outPath);
	
			//css = normalize(css, siteRoot, outPath);
		
			process.nextTick(function() {
				if (global._requirejsCssData) {
					css = global._requirejsCssData.css = css + global._requirejsCssData.css;
					delete global._requirejsCssData.usedBy.scss;
					if (Object.keys(global._requirejsCssData.usedBy).length === 0) {
						delete global._requirejsCssData;
					}
				}
		
				saveFile(outPath, compress(css));
			});
		} else {
			if (css === '')
				return;
			write(
				"(function(c){var d=document,a='appendChild',i='styleSheet',s=d.createElement('style');s.type='text/css';d.getElementsByTagName('head')[0][a](s);s[i]?s[i].cssText=c:s[a](d.createTextNode(c));})\n" +
				"('" + escape(compress(css)) + "');\n"
			);
		}

		//clear layer buffer for next layer
		layerBuffer = [];
	};
	
	return scssAPI;
	});