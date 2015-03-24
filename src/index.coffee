pathUtils = require('path')
fs = require('fs')
minify = require('html-minifier').minify

module.exports = class AngularTemplateCompiler
  brunchPlugin: yes
  type: 'template'
  extension: 'html'

  constructor: (config) ->
    @targetModule = config.plugins?.angularTemplates?.targetModule or 'templates'
    @prependPath = config.plugins?.angularTemplates?.prependPath or ''
    @htmlMinify = config.plugins?.angularTemplates?.htmlMinify or {}
    @firstFolderCount = false
    @currentCount = 0 

    @joinTo = if config.files then config.files.templates.joinTo else null
    @publicPath = if config.paths then config.paths.public else null
    
    @moduleNames = []
    
  escapeContent = (content) ->
    bsRegexp = new RegExp '\\\\', 'g'
    quoteRegexp = new RegExp '\\\'', 'g'
    
    nlReplace = '';

    content.replace(bsRegexp, '\\\\').replace(quoteRegexp, "\\'").replace /\r?\n/g, nlReplace

  getContent = (content, htmlmin) ->
    optionArray = []
    for i of htmlmin
      optionArray.push [i, htmlmin[i]]
    escapeContent minify(content, optionArray)

  compileTemplate = (moduleName, content, suffix, htmlmin) ->
    contentModified = getContent content, htmlmin

    "$templateCache.put('#{moduleName}','#{contentModified}'); #{suffix}"

  compile: (content, path, callback) ->
    suffix = ''

    if not @firstFolderCount
      htmlFiles = fs.readdirSync(pathUtils.dirname(path)).filter (item) -> pathUtils.extname(item) is '.html'
      @firstFolderCount = htmlFiles.length

    @currentCount++

    if @firstFolderCount is @currentCount
      suffix = "\n}]);"

    moduleName = @prependPath + pathUtils.basename(path)
    @moduleNames.push "'#{moduleName}'"

    callback(null, compileTemplate(moduleName, content, suffix, @htmlMinify))


  onCompile: (generatedFiles) ->
    bundle = ''
    joinToKeys = Object.keys @joinTo
    
    i = 0

    while i < joinToKeys.length
      path = @publicPath + pathUtils.sep + joinToKeys[i]
      bundle = """angular.module('#{@targetModule}', []).run(['$templateCache', function($templateCache) {\n"""
      
      pathExists = fs.statSync path

      if pathExists
        fileContent = fs.readFileSync(path, encoding: 'utf-8')

      if fileContent.indexOf(bundle) == -1
        fs.writeFile path, bundle.concat(fileContent), (err) ->
          if err then throw err
      i++