gulp   = require 'gulp'
plumber = require "gulp-plumber"
jade = require "gulp-jade"

#jade
gulp.task 'jade', ()->
  {approot,distPath,wwwroot} = global.pkg
  LOCALS = 
    wwwroot : wwwroot
  gulp.src [approot+'/src/jade/**/*.jade','!'+approot+'/src/jade/layout/*.*','!'+approot+'/src/jade/module/**/*.jade']
    .pipe plumber()
    .pipe jade
          locals: LOCALS
          pretty: true
    .pipe plumber.stop()
    .pipe gulp.dest distPath+'/html/'
