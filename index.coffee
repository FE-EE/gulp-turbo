_    = require 'lodash'
path = require 'path'
util = require 'gulp-util'
chalk = require 'chalk'
moment     = require 'moment'
requireDir = require 'require-dir'
defaultConf = require path.join(process.cwd(), './project-conf.json')
projectPkg = require path.join(process.cwd(), './package.json')
turboPkg = require './package.json'

{approot,distMode,domain,vhost,routerPath,httpPort} = defaultConf

defaultConf.routerPath = routerPath = '/'+routerPath.replace(/^\//,'')

domain     = domain.replace /^https?:\/\/|^\/\//, '//'
vhost      = vhost.replace /^https?:\/\/|^\/\//, '//'
				  .replace /\/$|\\$/,''
domain     = domain+':'+httpPort if httpPort*1 != 80

wwwroot    = (domain+routerPath.replace(/^\/\//,'/'))
			 
			 #replace tail /
			 .replace /\/$|\\$/,''

			 #replace first / 
			 .replace /^\/*||''/,'//'

util.log chalk.bgGreen 'wwwroot',wwwroot

#extends project config
extconf =
    base     : path.resolve approot,'../'
    distPath : approot+'/'+distMode
    wwwroot  : wwwroot
    vhost	 : vhost

global.pkg = _.assign defaultConf, extconf

projectPkg.currentDate = moment().format('YYYY-MM-DD HH:mm:ss')
global.turboPkg = turboPkg
global.projectPkg = projectPkg

requireDir './gulp'