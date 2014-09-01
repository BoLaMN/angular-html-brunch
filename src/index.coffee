module.exports = class AngularTemplateCompiler
  brunchPlugin: yes
  type: 'template'
  extension: 'html'

  constructor: (config) ->
    @moduleName = config.plugins?.angularTemplates?.moduleName or 'templates'
    @filenameOnly = config.plugins?.angularTemplates?.filenameOnly or false
    @prependPath = config.plugins?.angularTemplates?.prependPath or ''

  compile: (data, path, callback) ->
    if @filenameOnly
      path = path.replace /^.*[\\\/]/, ''
      path = @prependPath + path

    stringifyTemplate = (str) ->
      stringArray = '['
      str.split('\n').map (e, i) ->
        stringArray += "'" + e.replace(/'/g, "\\'") + "',"
      stringArray += "''" + '].join("\\n")'

    result =  """
              (function() {
                var module;
                try {
                  module = angular.module('#{@moduleName}');
                } catch (error) {
                  module = angular.module('#{@moduleName}', []);
                }
                module.run(['$templateCache', function($templateCache) {
                  return $templateCache.put('#{path}', #{stringifyTemplate(data)});
                }])
              })();
              """

    callback null, result
