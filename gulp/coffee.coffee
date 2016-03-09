gulp       = require 'gulp'
fs         = require 'fs'
util       = require 'gulp-util'
coffee     = require 'gulp-coffee'
through    = require 'through2'
sequence   = require 'gulp-sequence'
plumber    = require "gulp-plumber"

#支持不熟悉coffee的同学直接写js
gulp.task '_cpJs', ()->
  {approot}  = global.pkg

  gulp.src approot+'/src/coffee/**/*.js'
    .pipe gulp.dest approot+'/dev/js'

# coffee编译
gulp.task '_coffee', ()->
  {approot}  = global.pkg
  
  gulp.src [approot+'/src/coffee/**/*.coffee']
    .pipe plumber()
    .pipe coffee
            bare: true
          .on 'error', util.log
    .pipe plumber.stop()
    .pipe gulp.dest approot+'/dev/js'

# 拼装config
gulp.task '_addRequireConf', ()->
  {approot}  = global.pkg

  # 读取require config配置json数据
  requireConfPath = approot + '/src/coffee/require-conf.json'

  if fs.existsSync requireConfPath
    requireConf = fs.readFileSync requireConfPath, 'utf8'
    requireConfJson = JSON.parse requireConf
    # 对config添加baseUrl设置
    requireConfJson.baseUrl = global.pkg.wwwroot + '/js/'
    
    requireConf = 'require.config(' + JSON.stringify(requireConfJson) + ');'
    
    gulp.src [approot + '/dev/js/entry/**/*.js']
      .pipe through.obj (file, enc, cb)->
          contents = requireConf + '\n' + file.contents.toString()
          file.contents = new Buffer contents
          this.push file
          cb()
      .pipe gulp.dest approot+'/dev/js/entry/'

# coffee
gulp.task 'coffee', (cb)->
  sequence '_cpJs', '_coffee', '_addRequireConf', cb