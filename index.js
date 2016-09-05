// 解决fs创建文件默认的mode：666不生效的问题 https://github.com/nodejs/node-v0.x-archive/issues/25756
// 使之sudo状态下创建的文件，其他用户可直接读写访问
process.umask(0);

require('coffee-script').register();
require('./index.coffee');
