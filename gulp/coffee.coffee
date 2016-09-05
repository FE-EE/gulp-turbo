gulp       = require 'gulp'
path       = require 'path'
fs         = require 'fs'
util       = require 'gulp-util'
coffee     = require 'gulp-coffee'
through    = require 'through2'
sequence   = require 'gulp-sequence'
plumber    = require "gulp-plumber"
filter     = require 'gulp-filter'
chmod      = require 'gulp-chmod'

# coffee编译
#支持不熟悉coffee的同学直接写js
gulp.task 'coffee', ()->
  {approot,distPath}  = global.pkg

  coffeeFilter = filter '**/*.coffee', {restore: true}

  # 读取require config配置json数据
  requireConfPath = approot + '/src/coffee/require-conf.json'
  if fs.existsSync requireConfPath
    requireConf = fs.readFileSync requireConfPath, 'utf8'
    requireConfJson = JSON.parse requireConf
    # 设置baseurl
    # requireConfJson.baseUrl = '../js'
    # if distPath is 'dist'
    requireConfJson.baseUrl = global.pkg.wwwroot + '/js/'
    requireConf = 'require.config(' + JSON.stringify(requireConfJson) + ');'

  gulp.src [approot+'/src/coffee/**/*.js', approot+'/src/coffee/**/*.coffee']
    .pipe plumber()
    .pipe coffeeFilter
    .pipe coffee
            bare: true
          .on 'error', util.log
    .pipe coffeeFilter.restore
    .pipe through.obj (file, enc, cb)->
      # 对config添加baseUrl设置
      if /coffee[\/\\]+entry/.test(file.path) && requireConf
        contents = requireConf + '\n' + file.contents.toString()
        file.contents = new Buffer contents
      this.push file
      cb()
    .pipe chmod 777
    .pipe plumber.stop()
    .pipe gulp.dest approot+'/dev/js'
