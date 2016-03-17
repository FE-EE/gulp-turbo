gulp       = require 'gulp'
fs         = require 'fs'
chalk      = require 'chalk'
util       = require 'gulp-util'
requirejs  = require 'gulp-requirejs'
sourcemaps = require 'gulp-sourcemaps'
through    = require 'through2'
uglify     = require 'gulp-uglify'
rename     = require 'gulp-rename'
path       = require 'path'
# md5        = require 'md5'
revHash    = require 'rev-hash'
turboCache = require '../lib/turboCache'
mkdir      = require 'mkdirp'
plumber    = require "gulp-plumber"
header     = require 'gulp-header'

banner = ['/**',
  ' * <%= projectPkg.name %> v<%= projectPkg.version %>',
  ' * @update <%= projectPkg.currentDate %>',
  ' * @by <%= turboPkg.name %> v<%= turboPkg.version %> <%= turboPkg.homepage %>',
  ' */',
  ''].join('\n')

rjs_cache = {}
# 兼容老版本 合并压缩entry目录下的main JS
gulp.task 'rMin', ()->
  pkg = global.pkg
  {approot,distPath} = pkg
  
  rjs_cache = turboCache pkg.base

  # js目录下的所有js文件
  # js/entry目录下(包括子目录)的所有js文件，排除loder(_loder.js)伴生文件
  gulp.src [approot+'/dev/js/*.js', approot+'/dev/js/entry/**/*.js', '!'+approot+'/dev/js/entry/**/*_loder.js'],
      read: false
    .pipe rjs
      base: approot+'/dev/js/'
      dest: approot+'/dist/js/'
global.jsMainHashs = {}
rjs = ( opts ) ->
  through.obj ( file, enc, cb ) ->
    # 文件名带后缀名
    fname = path.basename file.path
    # 文件名截掉后缀名
    filename = path.basename file.path, '.js'
    # 文件所在目录
    filedir = path.dirname file.path
    # 目录所在相对(opts.base)路径
    relativePath = path.relative(opts.base, filedir).replace(/\\+/g, '\/')
    # 文件所在相对(opts.base)路径
    filepath = path.relative opts.base, file.path

    mainConfigFile = filedir + '/' + fname
    name = if relativePath then relativePath + '/' + filename else filename
    out = fname
    dist = opts.dest + relativePath
    fileMd5 = null
    # console.log mainConfigFile, name, out, dist
    requirejs
      baseUrl: opts.base
      mainConfigFile: mainConfigFile
      name: name
      out: out
      optimize: 'uglify2'
      paths: opts.paths or {}
      excludeShallow: opts.excludeShallow or []
      inlineText: true
      removeCombined: true
      findNestedDependencies: true
    .pipe plumber()
    .pipe through.obj (file, enc, cb)->
      fileMd5 = revHash file.contents
      jsMainHashs['js'+filepath.replace(/(\\+)|(\/+)/g, '')] = fileMd5
      result = rjs_cache.getFile fileMd5, filepath
      resultMap = rjs_cache.getFile fileMd5+'.map', filepath+'.map'
      if result
        _filepath = path.join(opts.dest, filepath)
        mkdir.sync path.dirname(_filepath)
        util.log '[js turboCache]: ', filepath, ' [', fileMd5, ']'
        fs.writeFileSync _filepath.replace(/\./, '-'+fileMd5+'.'), result
        # fs.writeFileSync _filepath, result
        # maps
        if resultMap
          _mapspath = path.dirname(_filepath)+'/.maps/'
          _mapsname = path.basename(_filepath)
          mkdir.sync _mapspath
          # fs.writeFileSync _mapspath+_mapsname.replace(/\.js$/, '_'+fileMd5+'.js.map'), resultMap
          fs.writeFileSync _mapspath+_mapsname+'.map', resultMap
      else
        this.push file
        cb()
    .pipe sourcemaps.init()
    .pipe uglify
      output:
        beautify: false
        indent_level: 1
    .pipe header(banner, global)
    .pipe sourcemaps.write '.maps'
    .pipe through.obj (file, enc, cb)->
      if !/\.maps/.test(file.path)
        util.log chalk.magenta '[js compress] ', filepath, ' --> ', file.contents.length, 'bytes [', fileMd5, ']'
        rjs_cache.setFile file.contents, fileMd5, filepath
      else
        rjs_cache.setFile file.contents, fileMd5+'.map', filepath+'.map'
      this.push file
      cb()
    .pipe rename (path)->
      if path.extname is '.js'
        path.basename += '-' + fileMd5
    .pipe plumber.stop()
    .pipe gulp.dest dist
    cb()
    return
