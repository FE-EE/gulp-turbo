gulp   = require 'gulp'
plumber = require "gulp-plumber"
wrapAmd = require 'gulp-wrap-amd'
jade = require "gulp-jade"
filter = require 'gulp-filter'
rename = require 'gulp-rename'
gulpif = require 'gulp-if'
lazypipe = require 'lazypipe'

#编译jade文件
gulp.task 'jade', ()->
  {approot,distPath,wwwroot,distMode} = global.pkg
  LOCALS = 
    wwwroot : wwwroot
  
  tojsFilter = filter approot+'/src/jade/module/**/*.jade', {restore: true}
  tohtmlFilter = filter '**/*.jade', {restore: true}
  isDist = distMode is 'dist'
  toDist = lazypipe()
    .pipe gulp.dest,approot+'/dist/'

  gulp.src [approot+'/src/jade/**/*.jade', '!'+approot+'/src/jade/layout/*.*']
    .pipe plumber()
    .pipe tojsFilter
    .pipe jade
      client: true
    .pipe wrapAmd
      deps: ['jade'],
      params: ['jade']
    .pipe rename (path)->
      path.dirname += '/../js/tpl/'
      return path
    .pipe tojsFilter.restore
    .pipe tohtmlFilter
    .pipe jade
          locals: LOCALS
          pretty: true
    .pipe rename (path)->
      path.dirname += '/html/'
      return path
    .pipe tohtmlFilter.restore
    .pipe plumber.stop()
    .pipe gulp.dest approot+'/dev/'
    .pipe gulpif isDist, toDist()