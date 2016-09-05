gulp   = require 'gulp'
plumber = require "gulp-plumber"
wrapAmd = require 'gulp-wrap-amd'
jade = require "gulp-jade"
filter = require 'gulp-filter'
rename = require 'gulp-rename'
gulpif = require 'gulp-if'
lazypipe = require 'lazypipe'
through    = require 'through2'
chmod      = require 'gulp-chmod'

#编译jade文件
gulp.task 'jade', ()->
  {approot,distMode, wwwroot} = global.pkg

  # 需要编译为js的jade模板文件
  tojsFilter = filter approot+'/src/jade/module/**/*.jade', {restore: true}
  # 需要编译为html的jade模板文件
  tohtmlFilter = filter '**/*.jade', {restore: true}
  # 是否为dist模式
  isDist = distMode is 'dist'
  # dist模式需要额外执行的流操作
  toDist = lazypipe()
    .pipe gulp.dest,approot+'/dist/'

  LOCALS =
    wwwroot: wwwroot

  gulp.src [approot+'/src/jade/**/*.jade', '!'+approot+'/src/jade/layout/**/*.*']
    .pipe plumber()

    # 将需要编译成js的jade文件进行编译处理
    .pipe tojsFilter
    .pipe jade
      client: true
    .pipe through.obj (file, enc, cb)->
      contents = 'var wwwroot = "' + LOCALS.wwwroot + '";\n' + file.contents.toString()
      file.contents = new Buffer contents
      this.push file
      cb()
    .pipe wrapAmd
      deps: ['jade'],
      params: ['jade']
      exports: 'template'
    # 重命名到js/tpl目录下
    .pipe rename (path)->
      path.dirname = path.dirname.replace 'module', 'js/tpl'
      return path
    .pipe tojsFilter.restore

    # 将需要编译成html的jade文件进行编译处理
    .pipe tohtmlFilter
    .pipe jade
          locals: LOCALS
          pretty: true
    .pipe rename (path)->
      path.dirname += '/html/'
      return path
    .pipe tohtmlFilter.restore

    .pipe chmod 777
    .pipe plumber.stop()
    .pipe gulp.dest approot+'/dev/'
    .pipe gulpif isDist, toDist()
