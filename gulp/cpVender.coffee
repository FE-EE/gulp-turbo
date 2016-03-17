gulp   = require 'gulp'
gulpif = require 'gulp-if'
lazypipe = require 'lazypipe'

# copy vender
gulp.task 'cpVender', ()->
  {approot,distMode} = global.pkg
  isDist = distMode is 'dist'

  cpVenderDist = lazypipe()
    .pipe gulp.dest,approot+'/dist/vender'

  gulp.src approot+'/src/vender/**/*.*'
    .pipe gulp.dest approot+'/dev/vender'
    .pipe gulpif isDist, cpVenderDist()