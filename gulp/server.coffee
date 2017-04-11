gulp            = require 'gulp'
pkg             = global.pkg
util            = require 'gulp-util'
fs              = require 'fs'
dns             = require 'dns'
request         = require 'request'
url             = require 'url'
path            = require 'path'
webserver       = require 'gulp-webserver'
chalk           = require 'chalk'
through         = require 'through2'
forceLivereload = if typeof(pkg.forceLivereload != 'undefined') then !!pkg.forceLivereload else distMode=='dev'

querystring     = require 'querystring'

PATH_REDIRECT = '/internal/redirect'

# webserver
gulp.task 'server', ()->
    util.log 'approot',pkg.approot
    {base,approot,isLucencyProxy,routerPath,distPath,wwwroot} = pkg

    # dist
    if pkg.distMode is 'dist'
      forceLivereload = false

    util.log chalk.magenta '本次服务以https模式运行，端口为 : '+pkg.httpsPort if pkg.https 

    util.log 'current webroot:',distPath
    gulp.src distPath
        .pipe webserver
            livereload       : forceLivereload
            host             : '0.0.0.0'
            path             : routerPath
            port             : if pkg.https then pkg.httpsPort or 443  else pkg.httpPort
            proxies          : pkg.serverProxies
            https            : pkg.https
            directoryListing :
              enable:true
              path:distPath

            middleware: (req, res, next)->
              urlObj    = url.parse(req.url, true)
              
              if urlObj.pathname == PATH_REDIRECT
                redirectParams = querystring.parse((urlObj.search || '').substr(1))
                irurl = redirectParams.irurl;
                if (irurl)
                  delete redirectParams.irurl
                  res.statusCode = 302
                  res.setHeader('Location', irurl + '?' + querystring.stringify(redirectParams))
                  res.end('')

              urlObj.protocol or= 'http'
              orginUrl = urlObj.protocol+wwwroot+req.url

              util.log 'Received request-->'+orginUrl

              # 解决IE9以上css不识别的问题
              if /.css([\?#].*)?$/.test orginUrl
                res.setHeader('Content-Type', 'text/css')
                next()
                return

              #replace to file path
              disk_path     = url.parse( path.normalize(base+req.url.replace(routerPath, '/'+distPath+'/')) ).pathname
              urlObj        = url.parse(req.url, true)
              method        = req.method

              # mock
              mockfile = approot+'/mock'+urlObj.pathname+'.json'
              if fs.existsSync mockfile
                res.setHeader('Content-Type', 'application/json')
                res.end fs.readFileSync mockfile
                return

              try
                stats         = fs.statSync disk_path
                # if is a file
                if stats.isFile disk_path
                  res.end fs.readFileSync disk_path
                  return

              #skip favicon.ico
              if req.url.search(/favicon\.ico$/)>-1
                console.log 'req.url',req.url
                console.log 'favicon'
                next()
                return
              
              #if local not found
              try
                fs.readdirSync disk_path
                next()
                return
              catch err
                if !isLucencyProxy
                  next()
                  return
                dns.resolve4 req.headers.host, (err, addresses)->
                  if err
                    res.writeHeader 500, 
                      'content-type': 'text/html'
                    res.write req.url
                    res.write err.toString()
                    res.end()
                  else
                    ip = addresses[0]
                    p = 'http://' + ip + req.url
                    req.headers['Host'] = req.headers.host

                    util.log chalk.magenta '本地资源不存在，触发透明代理 : '+ip+req.url
                    request
                      method: req.method,
                      url: p,
                      headers: req.headers
                    .pipe(res)
            fallback : ()->
              util.log 'fallback', arguments
              # request proxyURL, (error, response, body)->
              #     if (!error && response.statusCode == 200)
              #       next(body)
        .pipe through.obj (file, enc, cb)->
          util.log chalk.magenta 'running at '+wwwroot
          cb()
