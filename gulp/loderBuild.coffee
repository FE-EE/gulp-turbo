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

turboPkg = global.turboPkg
projectPkg = global.projectPkg
banner = ['/**',
  ' * '+projectPkg.name+' v'+projectPkg.version,
  ' * @hash #{hash}',
  ' * @by '+turboPkg.name+' v'+turboPkg.version+' '+turboPkg.homepage,
  ' */',
  ''].join('\n')

gulp.task 'loder-build', ()->
	pkg = global.pkg
	{approot,distPath,wwwroot} = pkg
	# html中loder引入部分
	loderHTMLC = '<div class="hide script-box"><base><script>document.write(\'<script role="loder" src="#{loderSrc}?_t=\' + new Date().getTime() +\'"><\\\/script>\');</script></div>'
	
	# filter
	htmlFilter = filter '**/*.html', {restore: true}

	# 记录当前正在处理的页面js主文件
	jsMainPath = ''
	return gulp.src approot+'/dist/html/*.html'
		.pipe useref({
			requirejs: (content, target, options)->
				jsMainHashs = global.jsMainHashs
				cHash = jsMainHashs[target.replace(/(\\+)|(\/+)/g, '')]
				if cHash
					_jsMainPath = wwwroot+'/'+target.replace('.js', '-'+cHash+'.js')
					content = content.replace(/data\-main=['"]{1}[^\s]+['"]{1}/, 'data-main="'+_jsMainPath+'"')
				return content
			requirejs_loder: (content, target, options)->
				jsMainPath = target
				jsMainRevHash target
				return loderHTMLC.replace /\#\{loderSrc\}/g, wwwroot+'/js/loder/'+path.basename(target)+'.js'
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
			if jsMainPath
				contents = buildLoder contents, jsMainPath
				jsMainPath = ''
			if pkg.isRemoveHash
				contents = contents.replace(/\-[0-9a-z]{10}\.(js|css)/g, '.$1')
			file.contents = new Buffer contents
			this.push file
			cb()
		.pipe htmlFilter.restore
		# html处理 end
		.pipe gulp.dest approot+'/dist'


buildRequirejs = (target)->
	pkg = global.pkg
	{approot,distPath,wwwroot} = pkg

	_jsMainPath = approot+'/dist/js/'+target+'.js'
	buildHashJs = ()->
		try
			fs.accessSync _jsMainPath
			jsMainContent = fs.readFileSync _jsMainPath
			jsHash = revHash jsMainContent
			fs.writeFileSync _jsMainPath.replace(/\.js$/, '-'+jsHash+'.js'), jsMainContent
			cb wwwroot+'/'+target.replace(/\.js$/, '-'+jsHash+'.js')
		catch e
			setTimeout ()->
				buildHashJs()
			,50
	buildHashJs()

# publish任务虽然放在了rMin后面，rMin执行后再执行，但存在问题，虽然看似rMin执行完了，但这个时候直接读取dist下js文件时，依然提示不存在，抛出错误
# 暂时先只好这样了
jsMainPathMap = {}
jsMainRevHash = (target)->
	pkg = global.pkg
	{approot,distPath,wwwroot} = pkg

	_jsMainPath = approot+'/dist/js/'+target+'.js'
	buildHashJs = ()->
		try
			fs.accessSync _jsMainPath
			jsMainContent = fs.readFileSync _jsMainPath
			jsHash = revHash jsMainContent
			fs.writeFileSync _jsMainPath.replace(/\.js$/, '-'+jsHash+'.js'), jsMainContent
			jsMainPathMap[target] = jsHash
		catch e
			setTimeout ()->
				buildHashJs()
			,50
	buildHashJs()

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
		if jsMainPathMap[jsMainPath]
			cb jsMainPath+'-'+jsMainPathMap[jsMainPath]
		else
			setTimeout ()->
				getJsMainPath jsMainPath, cb
			,50
	content = getConts(content)
	getJsMainPath jsMainPath, (jspath)->
		jspath = wwwroot+'/js/'+jspath
		conts.push mainJs.replace(/\#\{mainJs\}/, jspath)
		mkdir.sync approot+'/dist/js/loder/'
		loderPath = approot+'/dist/js/loder/'+path.basename(jsMainPath)+'.js'
		loderCont = loderTpl.replace(/\#\{conts\}/, JSON.stringify(conts))
		loderCont = banner.replace(/\#\{hash\}/g, revHash(new Buffer(loderCont)))+loderCont
		fs.writeFileSync loderPath, loderCont
	return content