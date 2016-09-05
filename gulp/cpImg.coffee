gulp       = require 'gulp'
chmod      = require 'gulp-chmod'

# copy images
gulp.task 'cpImg', ()->
  {approot,distPath} = global.pkg
  gulp.src approot+'/src/img/**/*.*'
    .pipe chmod 777
    .pipe gulp.dest distPath+'/img'
