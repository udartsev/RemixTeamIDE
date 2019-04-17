'use strict'
var StaticAnalysisRunner = require('remix-analyzer').CodeAnalysis
var yo = require('yo-yo')
var $ = require('jquery')
var remixLib = require('remix-lib')
var utils = remixLib.util

var styleGuide = require('../ui/styles-guide/theme-chooser')
var styles = styleGuide.chooser()

var css = require('./styles/staticAnalysisView-styles')
var globlalRegistry = require('../../global/registry')

var EventManager = require('../../lib/events')

function staticAnalysisView (localRegistry) {
  var self = this
  this.event = new EventManager()
  this.view = null
  this.runner = new StaticAnalysisRunner()
  this.modulesView = this.renderModules()
  this.lastCompilationResult = null
  this.lastCompilationSource = null
  self._components = {}
  self._components.registry = localRegistry || globlalRegistry
  // dependencies
  self._deps = {
    pluginManager: self._components.registry.get('pluginmanager').api,
    renderer: self._components.registry.get('renderer').api,
    offsetToLineColumnConverter: self._components.registry.get('offsettolinecolumnconverter').api
  }

  self._deps.pluginManager.event.register('sendCompilationResult', (file, source, languageVersion, data) => {
    self.lastCompilationResult = null
    self.lastCompilationSource = null
    $('#staticanalysisresult').empty()
    self.lastCompilationResult = data
    self.lastCompilationSource = source
    if (self.view.querySelector('#autorunstaticanalysis').checked) {
      self.run()
    }
  })
}

staticAnalysisView.prototype.render = function () {
  var self = this
  var view = yo`
    <div class="${css.analysis}">
      <div id="staticanalysismodules">
        ${this.modulesView}
      </div>
      <div class="${css.buttons}">
        <button class="${css.buttonRun}" onclick="${function () { self.run() }}" >Run</button>
        <label class="${css.label}" for="autorunstaticanalysis">
          <input id="autorunstaticanalysis"
            type="checkbox"
            style="vertical-align:bottom"
            checked="true"
          >
          Auto run
        </label>
        <label class="${css.label}" for="checkAllEntries">
          <input id="checkAllEntries"
            type="checkbox"
            onclick="${function (event) { self.checkAll(event) }}"
            style="vertical-align:bottom"
            checked="true"
          >
          Check/Uncheck all
        </label>
      </div>
      <div class="${css.result}" "id='staticanalysisresult'></div>
    </div>
  `
  if (!this.view) {
    this.view = view
  }
  return view
}

staticAnalysisView.prototype.selectedModules = function () {
  if (!this.view) {
    return []
  }
  var selected = this.view.querySelectorAll('[name="staticanalysismodule"]:checked')
  var toRun = []
  for (var i = 0; i < selected.length; i++) {
    toRun.push(selected[i].attributes['index'].value)
  }
  return toRun
}

staticAnalysisView.prototype.run = function () {
  if (!this.view) {
    return
  }
  var selected = this.selectedModules()
  var warningContainer = $('#staticanalysisresult')
  warningContainer.empty()
  if (this.lastCompilationResult) {
    var self = this
    var warningCount = 0
    this.runner.run(this.lastCompilationResult, selected, function (results) {
      results.map(function (result, i) {
        result.report.map(function (item, i) {
          var location = ''
          if (item.location !== undefined) {
            var split = item.location.split(':')
            var file = split[2]
            location = {
              start: parseInt(split[0]),
              length: parseInt(split[1])
            }
            location = self._deps.offsetToLineColumnConverter.offsetToLineColumn(location,
              parseInt(file),
              self.lastCompilationSource.sources,
              self.lastCompilationResult.sources)
            location = Object.keys(self.lastCompilationResult.contracts)[file] + ':' + (location.start.line + 1) + ':' + (location.start.column + 1) + ':'
          }
          warningCount++
          var msg = yo`<span>${location} ${item.warning} ${item.more ? yo`<span><br><a href="${item.more}" target="blank">more</a></span>` : yo`<span></span>`}</span>`
          self._deps.renderer.error(msg, warningContainer, { type: 'staticAnalysisWarning', useSpan: true })
        })
      })
      if (warningContainer.html() === '') {
        $('#righthand-panel #menu .staticanalysisView').css('color', '')
        warningContainer.html('No warning to report')
      } else {
        $('#righthand-panel #menu .staticanalysisView').css('color', styles.colors.red)
      }
      self.event.trigger('staticAnaysisWarning', [warningCount])
    })
  } else {
    warningContainer.html('No compiled AST available')
  }
}

staticAnalysisView.prototype.checkModule = function (event) {
  let selected = this.view.querySelectorAll('[name="staticanalysismodule"]:checked')
  let checkAll = this.view.querySelector('[id="checkAllEntries"]')
  if (event.target.checked) {
    checkAll.checked = true
  } else if (!selected.length) {
    checkAll.checked = false
  }
}

staticAnalysisView.prototype.checkAll = function (event) {
  if (!this.view) {
    return
  }
  // checks/unchecks all
  var checkBoxes = this.view.querySelectorAll('[name="staticanalysismodule"]')
  checkBoxes.forEach((checkbox) => { checkbox.checked = event.target.checked })
}

staticAnalysisView.prototype.renderModules = function () {
  var self = this
  var groupedModules = utils.groupBy(preProcessModules(self.runner.modules()), 'categoryId')
  return Object.keys(groupedModules).map((categoryId, i) => {
    var category = groupedModules[categoryId]
    var entriesDom = category.map((item, i) => {
      return yo`
        <label class="${css.label}">
          <input id="staticanalysismodule_${categoryId}_${i}"
            type="checkbox"
            class="staticAnalysisItem"
            name="staticanalysismodule"
            index=${item._index}
            checked="true"
            style="vertical-align:bottom"
            onclick="${function (event) { self.checkModule(event) }}"
            >
          ${item.name}
          ${item.description}
        </label>
            `
    })
    return yo`<div class="${css.analysisModulesContainer}">
                <label class="${css.label}"><b>${category[0].categoryDisplayName}</b></label>
                ${entriesDom}
              </div>`
  })
}

module.exports = staticAnalysisView

function preProcessModules (arr) {
  return arr.map((item, i) => {
    item['_index'] = i
    item.categoryDisplayName = item.category.displayName
    item.categoryId = item.category.id
    return item
  })
}
