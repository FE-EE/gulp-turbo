fs         = require 'fs'
path       = require 'path'
gulp       = require 'gulp'
rev        = require 'gulp-rev'
revReplace = require 'gulp-rev-replace'
useref     = require 'gulp-useref'
# filter     = require 'gulp-filter'
through    = require 'through2'
revHash    = require 'rev-hash'
_          = require 'lodash'
moment     = require 'moment'
mkdir      = require 'mkdirp'

gulp.task 'loder-build', ()->
	pkg = global.pkg
	{approot,distPath,wwwroot} = pkg
	# html中loder引入部分
	loderHTMLC = '<div class="hide script-box"><base><script>document.write(\'<script role="loder" src="#{loderSrc}?_t=\' + new Date().getTime() +\'"><\\\/script>\');</script></div>'
	
	# 记录当前正在处理的页面js主文件
	jsMainPath = ''
	return gulp.src approot+'/dist/html/*.html'
		.pipe useref({
			requirejs: (content, target, options)->
				jsMainPath = target
				jsMainRevHash target
				return loderHTMLC.replace /\#\{loderSrc\}/g, wwwroot+'/js/loder/'+path.basename(target)+'.js'
		})
		.pipe rev()
		.pipe revReplace({
			prefix: wwwroot+'/'
		})
		.pipe through.obj (file, enc, cb)->
			if /\.html$/.test(file.path)
				# 构建loder文件
				if jsMainPath
					contents = buildLoder file.contents.toString(), jsMainPath
					jsMainPath = ''
					# 处理html文件，html文件不加hash后缀，并且输出到html目录下
					# fs.writeFileSync approot+'/dist/html/'+path.basename(file.path), contents
					fs.writeFileSync approot+'/dist/html/'+path.basename(file.path).replace(/\-\w{10}\.html/, '.html'), contents
			else
				this.push file
			cb()
		.pipe gulp.dest approot+'/dist'

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
		'/** loder v2.0 **/\n(function (window, undefined){',
			'var conts = #{conts};',
			'document.write(conts.join(""));',
		'})(window);\n/** update '+moment().format('YYYY-MM-DD hh:mm:ss')+' **/'
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
		mkdirp.sync approot+'/dist/js/loder/'
		fs.writeFileSync approot+'/dist/js/loder/'+path.basename(jsMainPath)+'.js', loderTpl.replace(/\#\{conts\}/, JSON.stringify(conts))
	return content