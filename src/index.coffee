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
    quoteRegexp = new RegExp '\\"', 'g'
    
    nlReplace = '\\n"+\n"';

    content.replace(bsRegexp, '\\\\').replace(quoteRegexp, '\\"').replace /\r?\n/g, nlReplace

  getContent = (content, htmlmin) ->
    if Object.keys(htmlmin).length
      optionArray = []
      for i of htmlmin
        optionArray.push [i, htmlmin[i]]
      content = minify(content, optionArray)
    escapeContent content


  compileTemplate = (moduleName, content, suffix) ->
    contentModified = getContent content, @htmlMinify

    "$templateCache.put(\"#{moduleName}\",\"#{contentModified}\");\n #{suffix}"

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

    callback(null, compileTemplate(moduleName, content, suffix))


  onCompile: (generatedFiles) ->
    bundle = ''
    joinToKeys = Object.keys @joinTo
    
    i = 0

    while i < joinToKeys.length
      path = @publicPath + pathUtils.sep + joinToKeys[i]
      bundle = """var module = angular.module('#{@targetModule}', []);\n
        module.run(['$templateCache', function($templateCache) {\n\n"""
      
      pathExists = fs.statSync path

      if pathExists
        fileContent = fs.readFileSync(path, encoding: 'utf-8')

      if fileContent.indexOf(bundle) == -1
        fs.writeFile path, bundle.concat(fileContent), (err) ->
          if err then throw err
      i++