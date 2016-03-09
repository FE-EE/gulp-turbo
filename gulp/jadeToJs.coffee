gulp    = require 'gulp'
jade    = require 'gulp-jade'
wrapAmd = require 'gulp-wrap-amd'
plumber = require "gulp-plumber"
# jade to js
gulp.task 'jadeToJs', ()->
  {approot,wwwroot} = global.pkg
  gulp.src [approot+'/src/jade/module/**/*.jade']
    .pipe plumber()
    .pipe jade
          client: true
    .pipe wrapAmd
        deps: ['jade'],
        params: ['jade']
    .pipe plumber.stop()
    .pipe gulp.dest approot+'/dev/js/tpl/'
