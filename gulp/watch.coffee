gulp   = require 'gulp'
chalk = require 'chalk'
util   = require 'gulp-util'
sequence = require 'gulp-sequence'

# watcher
gulp.task 'watch',[],()->
  pkg = global.pkg
  {approot,distMode} = pkg

  if distMode is 'dev'
    # jade
    jade_watcher = gulp.watch approot + '/src/**/*.jade', ['jade']
    jade_watcher.on 'change', (event)->
      util.log chalk.green('[File change] ') + event.path + ' was ' + event.type + ', running jade tasks...'

    # stylus
    stylus_watcher = gulp.watch approot + '/src/**/*.styl', ['stylus']
    stylus_watcher.on 'change', (event)->
      util.log chalk.green('[File change] ') + event.path + ' was ' + event.type + ', running stylus tasks...'

    #coffee
    coffee_watcher = gulp.watch [approot + '/src/**/*.coffee',approot + '/src/**/*.js',approot + '/src/coffee/require-conf.json'], ['coffee']
    coffee_watcher.on 'change', (event)->
      util.log chalk.green('[File change] ') + event.path + ' was ' + event.type + ', running coffee tasks...'

    #cpImg
    cpImg_watcher = gulp.watch [approot + '/src/img/**/*.*'], ['cpImg']
    cpImg_watcher.on 'change', (event)->
      util.log chalk.green('[File change] ') + event.path + ' was ' + event.type + ', running cpImg tasks...'

    #cpVender
    cpVender_watcher = gulp.watch [approot + '/src/vender/**/*.*'], ['cpVender']
    cpVender_watcher.on 'change', (event)->
      util.log chalk.green('[File change] ') + event.path + ' was ' + event.type + ', running cpVender tasks...'
  else
    #rMin
    rebuild_watcher = gulp.watch [approot + '/src/**/*.*'], ['build']
    rebuild_watcher.on 'change', (event)->
      util.log chalk.green('[File change] ') + event.path + ' was ' + event.type + ', running rebuild tasks...'