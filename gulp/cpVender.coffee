gulp   = require 'gulp'
gulpif = require 'gulp-if'
lazypipe = require 'lazypipe'
chmod      = require 'gulp-chmod'

# copy vender
gulp.task 'cpVender', ()->
  {approot,distMode} = global.pkg
  isDist = distMode is 'dist'

  cpVenderDist = lazypipe()
    .pipe gulp.dest,approot+'/dist/vender'

  gulp.src approot+'/src/vender/**/*.*'
    .pipe chmod 777
    .pipe gulp.dest approot+'/dev/vender'
    .pipe gulpif isDist, cpVenderDist()
