gulp       = require 'gulp'
util       = require 'gulp-util'
chalk      = require 'chalk'
stylus     = require 'gulp-stylus'
sourcemaps = require 'gulp-sourcemaps'
through    = require 'through2'
_          = require 'lodash'
path       = require 'path'
plumber = require "gulp-plumber"
gulpif = require "gulp-if"
autoprefixer = require 'gulp-autoprefixer'
minifyCSS = require 'gulp-minify-css'

# stylus - with sourcemaps
gulp.task 'stylus', ()->
  pkg = global.pkg
  {base,approot,distMode,distPath} = pkg
  if(distMode is 'dist')
    isCompress = true

  gulp.src [approot+'/src/stylus/**/*.styl','!'+approot+'/src/stylus/module/**/*.styl']
    .pipe plumber()
    # .pipe gulpif(isCompress, sourcemaps.init())
    .pipe stylus
      compress: false
    .pipe autoprefixer()
    .pipe gulpif isCompress,minifyCSS()
    .pipe gulpif isCompress,through.obj (file, enc, cb)->
      util.log chalk.cyan('[stylus compress] ', path.relative(approot + '/src/stylus/', file.path), ' --> ', file.contents.length, 'bytes')
      this.push file
      cb()
    # .pipe gulpif(isCompress, sourcemaps.write('.maps'))
    .pipe plumber.stop()
    .pipe gulp.dest distPath+'/css/'
