gulp       = require 'gulp'
del        = require 'del'
chalk      = require 'chalk'
util       = require 'gulp-util'

# 清除turboCache
gulp.task 'clean-turboCache', (cb)->
	{approot}  = global.pkg
	util.log chalk.yellow '清除turboCache'
	del [global.pkg.base + '/.turboCache'], cb

# 清除dev和dist文件夹
gulp.task 'clean', (cb)->
	{approot}  = global.pkg
	util.log chalk.yellow '清除dev和dist文件夹'
	del [approot + '/dev', approot + '/dist'], cb