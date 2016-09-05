fs         = require 'fs'
path       = require 'path'
gulp       = require 'gulp'
rev        = require 'gulp-rev'
revReplace = require 'gulp-rev-replace'
useref     = require 'gulp-useref'
through    = require 'through2'
revHash    = require 'rev-hash'
_          = require 'lodash'
mkdir      = require 'mkdirp'
header     = require 'gulp-header'
filter     = require 'gulp-filter'
rename     = require 'gulp-rename'
chmod      = require 'gulp-chmod'

turboPkg = global.turboPkg
projectPkg = global.projectPkg

# loder文件头部注释信息
banner = ['/**',
  ' * '+projectPkg.name+' v'+projectPkg.version,
  ' * @hash #{hash}',
  ' * @by '+turboPkg.name+' v'+turboPkg.version+' '+turboPkg.homepage,
  ' */',
  ''].join('\n')

gulp.task 'loder-build', ()->
	pkg = global.pkg
	{approot,distPath,wwwroot} = pkg

	# 需引入loder时， html中loder部分模板
	loderHTMLC = '<!--$#{target}$--><div class="hide script-box"><base><script>document.write(\'<script role="loder" src="#{loderSrc}?_t=\' + new Date().getTime() +\'"><\\\/script>\');</script></div>'

	# filter 过滤html文件
	htmlFilter = filter '**/*.html', {restore: true}

	return gulp.src approot+'/dist/html/*.html'
		.pipe useref({
			# requirejs script data-main 处理
			requirejs: (content, target, options)->
				jsMainHashs = global.jsMainHashs
				cHash = jsMainHashs[target.replace(/(\\+)|(\/+)/g, '')]
				if cHash
					_jsMainPath = wwwroot+'/'+target.replace('.js', '-'+cHash+'.js')
					content = content.replace(/data\-main=['"]{1}[^\s]+['"]{1}/, 'data-main="'+_jsMainPath+'"')

				content = content.replace '..', wwwroot
				return content
			requirejs_loder: (content, target, options)->
				return loderHTMLC.replace /\#\{loderSrc\}/g, wwwroot+'/js/loder/'+path.basename(target)+'.js'
								 .replace /\#\{target\}/g, target
		})
		.pipe rev()
		.pipe revReplace({
			prefix: wwwroot+'/'
		})
		# html处理
		.pipe htmlFilter
		.pipe rename (path)->
			path.dirname += '/html'
			path.basename = path.basename.replace(/\-\w{10}$/, '')
			return path
		.pipe through.obj (file, enc, cb)->
			contents = file.contents.toString()
			# 构建loder文件
			if /\<\!\-\-\$([^$]+)\$\-\-\>/.test(contents)
				contents = buildLoder contents.replace(/\<\!\-\-\$([^$]+)\$\-\-\>/, ''), RegExp.$1
			if pkg.isRemoveHash
				contents = contents.replace(/\-[0-9a-z]{10}\.(js|css)/g, '.$1')
			file.contents = new Buffer contents
			this.push file
			cb()
		.pipe htmlFilter.restore
    .pipe chmod 777
		# html处理 end
		.pipe gulp.dest approot+'/dist'

buildLoder = (content, jsMainPath)->
	pkg = global.pkg
	{approot,distPath,wwwroot} = pkg
	loderTpl = [
		'(function (){',
			'var conts = #{conts};',
			'document.write(conts.join(""));',
		'})();'
	].join('')
	startFlag = '<!-- loder control -->'
	endFlag = '<!-- endloder -->'
	mainJs = '<script data-main="#{mainJs}" src="'+wwwroot+'/vender/require.js"></script>';
	conts = []
	getConts = (content)->
		from = content.indexOf startFlag
		to = content.indexOf endFlag, from
		if from is -1
			return content
		cont = content.slice from, to+endFlag.length
		cont = cont.slice startFlag.length, cont.length-endFlag.length
		cont = _.trim cont
		content = content.substring(0, from) + content.substring(to+endFlag.length)
		conts.push cont
		getConts content
	getJsMainPath = (jsMainPath, cb)->
		jsMainHashs = global.jsMainHashs
		cHash = jsMainHashs[jsMainPath.replace(/(\\+)|(\/+)/g, '') + '.js']
		if cHash
			cb jsMainPath.replace /(\.js)?$/, '-'+cHash+'$1'
		else
			setTimeout ()->
				getJsMainPath jsMainPath, cb
			,50
	content = getConts(content)
	getJsMainPath jsMainPath, (jspath)->
		jspath = wwwroot+'/'+jspath
		conts.push mainJs.replace(/\#\{mainJs\}/, jspath)
		mkdir.sync approot+'/dist/js/loder/'
		loderPath = approot+'/dist/js/loder/'+path.basename(jsMainPath)+'.js'
		loderCont = loderTpl.replace(/\#\{conts\}/, JSON.stringify(conts))
		loderCont = banner.replace(/\#\{hash\}/g, revHash(new Buffer(loderCont)))+loderCont
		fs.writeFileSync loderPath, loderCont
	return content
