/* global Node, requestAnimationFrame */
var yo = require('yo-yo')
var javascriptserialize = require('javascript-serialize')
var jsbeautify = require('js-beautify')
var ethers = require('ethers')
var type = require('component-type')
var vm = require('vm')
var EventManager = require('../../lib/events')
var Web3 = require('web3')
var swarmgw = require('swarmgw')()

var CommandInterpreterAPI = require('../../lib/cmdInterpreterAPI')
var executionContext = require('../../execution-context')
var Dropdown = require('../ui/dropdown')
var AutoCompletePopup = require('../ui/auto-complete-popup')
var Commands = require('../constants/commands')

var csjs = require('csjs-inject')
var styleGuide = require('../ui/styles-guide/theme-chooser')
var styles = styleGuide.chooser()

var css = require('./styles/terminal-styles')

var KONSOLES = []

function register (api) { KONSOLES.push(api) }

var ghostbar = yo`<div class=${css.ghostbar}></div>`

class Terminal {
  constructor (opts, api) {
    var self = this
    self.event = new EventManager()
    self._api = api
    self._opts = opts
    self.data = {
      lineLength: opts.lineLength || 80,
      session: [],
      activeFilters: { commands: {}, input: '' },
      filterFns: {}
    }
    self._view = { el: null, bar: null, input: null, term: null, journal: null, cli: null }
    self._components = {}
    self._components.cmdInterpreter = new CommandInterpreterAPI(this)
    self._components.dropdown = new Dropdown({
      options: [
        'only remix transactions',
        'all transactions',
        'script'
      ],
      defaults: ['only remix transactions', 'script'],
      dependencies: { 'all transactions': ['only remix transactions'], 'only remix transactions': ['all transactions'] }
    })
    self._components.dropdown.event.register('deselect', function (label) {
      self.event.trigger('filterChanged', ['deselect', label])
      if (label === 'script') {
        self.updateJournal({ type: 'deselect', value: label })
      }
    })
    self._components.dropdown.event.register('select', function (label) {
      self.event.trigger('filterChanged', ['select', label])
      if (label === 'script') {
        self.updateJournal({ type: 'select', value: label })
      }
    })
    self._components.autoCompletePopup = new AutoCompletePopup()
    self._components.autoCompletePopup.event.register('handleSelect', function (input) {
      self._components.autoCompletePopup.data._options = []
      self._components.autoCompletePopup._startingElement = 0
      let textList = self._view.input.innerText.split(' ')
      textList.pop()
      textList.push(input)
      self._view.input.innerText = `${textList}`.replace(/,/g, ' ')
      self._view.input.focus()
      yo.update(self._view.autoCompletePopup, self._components.autoCompletePopup.render())
    })
    self._components.autoCompletePopup.event.register('updateList', function () {
      yo.update(self._view.autoCompletePopup, self._components.autoCompletePopup.render())
    })
    self._commands = {}
    self.commands = {}
    self._JOURNAL = []
    self._jobs = []
    self._INDEX = {}
    self._INDEX.all = []
    self._INDEX.allMain = []
    self._INDEX.commands = {}
    self._INDEX.commandsMain = {}
    self.registerCommand('html', self._blocksRenderer('html'), { activate: true })
    self.registerCommand('log', self._blocksRenderer('log'), { activate: true })
    self.registerCommand('info', self._blocksRenderer('info'), { activate: true })
    self.registerCommand('warn', self._blocksRenderer('warn'), { activate: true })
    self.registerCommand('error', self._blocksRenderer('error'), { activate: true })
    self.registerCommand('script', function execute (args, scopedCommands, append) {
      var script = String(args[0])
      scopedCommands.log(`> ${script}`)
      self._shell(script, scopedCommands, function (error, output) {
        if (error) scopedCommands.error(error)
        else scopedCommands.log(output)
      })
    }, { activate: true })
    function basicFilter (value, query) { try { return value.indexOf(query) !== -1 } catch (e) { return false } }

    self.registerFilter('log', basicFilter)
    self.registerFilter('info', basicFilter)
    self.registerFilter('warn', basicFilter)
    self.registerFilter('error', basicFilter)
    self.registerFilter('script', basicFilter)

    self._jsSandboxContext = {}
    self._jsSandboxRegistered = {}
    if (opts.shell) self._shell = opts.shell
    register(self)
  }
  render () {
    var self = this
    if (self._view.el) return self._view.el
    self._view.journal = yo`<div class=${css.journal}></div>`
    self._view.input = yo`
      <span class=${css.input} contenteditable="true" onpaste=${paste} onkeydown=${change}></span>
    `
    self._view.input.innerText = '\n'
    self._view.cli = yo`
      <div class=${css.cli}>
        <span class=${css.prompt}>${'>'}</span>
        ${self._view.input}
      </div>
    `
    self._view.icon = yo`
      <i onmouseenter=${hover} onmouseleave=${hover} onmousedown=${minimize}
      class="${css.toggleTerminal} fa fa-angle-double-down"></i>`
    self._view.dragbar = yo`
      <div onmousedown=${mousedown} class=${css.dragbarHorizontal}></div>`
    self._view.dropdown = self._components.dropdown.render()
    self._view.pendingTxCount = yo`<div class=${css.pendingTx} title='Pending Transactions'>0</div>`
    self._view.bar = yo`
      <div class=${css.bar}>
        ${self._view.dragbar}
        <div class=${css.menu}>
          ${self._view.icon}
          <div class=${css.clear} onclick=${clear}>
            <i class="fa fa-ban" aria-hidden="true" title="Clear console"
            onmouseenter=${hover} onmouseleave=${hover}></i>
          </div>
          ${self._view.pendingTxCount}
          <div class=${css.verticalLine}></div>
          <div class=${css.listen}>
            <input onchange=${listenOnNetwork} type="checkbox"
            title="If checked Remix will listen on all transactions mined in the current environment and not only transactions created by you">
          </div>
          ${self._view.dropdown}
          <div class=${css.search}>
            <i class="fa fa-search ${css.searchIcon}" aria-hidden="true"></i>
            <input type="text" class=${css.filter} onkeydown=${filter}  placeholder="Search transactions">
          </div>
        </div>
      </div>
    `
    self._view.term = yo`
      <div class=${css.terminal_container} onscroll=${throttle(reattach, 10)} onclick=${focusinput}>
        <div class=${css.terminal}>
            ${self._view.journal}
            ${self._view.cli}
        </div>
      </div>
    `
    self._view.autoCompletePopup = self._components.autoCompletePopup.render()
    self._view.el = yo`
      <div class=${css.panel}>
        ${self._view.bar}
        ${self._view.term}
      </div>
    `
    setInterval(() => {
      self._view.pendingTxCount.innerHTML = self._opts.udapp.pendingTransactionsCount()
    }, 1000)

    function listenOnNetwork (ev) {
      self.event.trigger('listenOnNetWork', [ev.currentTarget.checked])
    }
    function paste (event) {
      const selection = window.getSelection()
      if (!selection.rangeCount) return false
      event.preventDefault()
      event.stopPropagation()
      var clipboard = (event.clipboardData || window.clipboardData)
      var text = clipboard.getData('text/plain')
      text = text.replace(/[^\x20-\xFF]/gi, '') // remove non-UTF-8 characters
      var temp = document.createElement('div')
      temp.innerHTML = text
      var textnode = document.createTextNode(temp.textContent)
      selection.getRangeAt(0).insertNode(textnode)
      selection.empty()
      self.scroll2bottom()
      placeCaretAtEnd(event.currentTarget)
    }
    function placeCaretAtEnd (el) {
      el.focus()
      var range = document.createRange()
      range.selectNodeContents(el)
      range.collapse(false)
      var sel = window.getSelection()
      sel.removeAllRanges()
      sel.addRange(range)
    }
    function throttle (fn, wait) {
      var time = Date.now()
      return function debounce () {
        if ((time + wait - Date.now()) < 0) {
          fn.apply(this, arguments)
          time = Date.now()
        }
      }
    }
    var css2 = csjs`
      .anchor            {
        position         : static;
        border-top       : 2px dotted blue;
        height           : 10px;
      }
      .overlay           {
        position         : absolute;
        width            : 100%;
        display          : flex;
        align-items      : center;
        justify-content  : center;
        bottom           : 0;
        right            : 15px;
        min-height       : 20px;
      }
      .text              {
        z-index          : 2;
        color            : black;
        font-weight      : bold;
        pointer-events   : none;
      }
      .background        {
        z-index          : 1;
        opacity          : 0.8;
        background-color : #a6aeba;
        cursor           : pointer;
      }
      .ul                 {
        padding-left     : 20px;
        padding-bottom   : 5px;
      }
    `
    var text = yo`<div class="${css2.overlay} ${css2.text}"></div>`
    var background = yo`<div class="${css2.overlay} ${css2.background}"></div>`
    var placeholder = yo`<div class=${css2.anchor}>${background}${text}</div>`
    var inserted = false

    window.addEventListener('resize', function (event) {
      self.event.trigger('resize', [])
      self.event.trigger('resize', [])
    })

    function focusinput (event) {
      if (self._view.journal.offsetHeight - (self._view.term.scrollTop + self._view.term.offsetHeight) < 50) {
        refocus()
      }
    }
    function refocus () {
      self._view.input.focus()
      reattach({ currentTarget: self._view.term })
      delete self.scroll2bottom
      self.scroll2bottom()
    }
    function reattach (event) {
      var el = event.currentTarget
      var isBottomed = el.scrollHeight - el.scrollTop - el.clientHeight < 30
      if (isBottomed) {
        if (inserted) {
          text.innerText = ''
          background.onclick = undefined
          self._view.journal.removeChild(placeholder)
        }
        inserted = false
        delete self.scroll2bottom
      } else {
        if (!inserted) self._view.journal.appendChild(placeholder)
        inserted = true
        check()
        if (!placeholder.nextElementSibling) {
          placeholder.style.display = 'none'
        } else {
          placeholder.style = ''
        }
        self.scroll2bottom = function () {
          var next = placeholder.nextElementSibling
          if (next) {
            placeholder.style = ''
            check()
            var messages = 1
            while ((next = next.nextElementSibling)) messages += 1
            text.innerText = `${messages} new unread log entries`
          } else {
            placeholder.style.display = 'none'
          }
        }
      }
    }
    function check () {
      var pos1 = self._view.term.offsetHeight + self._view.term.scrollTop - (self._view.el.offsetHeight * 0.15)
      var pos2 = placeholder.offsetTop
      if ((pos1 - pos2) > 0) {
        text.style.display = 'none'
        background.style.position = 'relative'
        background.style.opacity = 0.3
        background.style.right = 0
        background.style.borderBox = 'content-box'
        background.style.padding = '2px'
        background.style.height = (self._view.journal.offsetHeight - (placeholder.offsetTop + placeholder.offsetHeight)) + 'px'
        background.onclick = undefined
        background.style.cursor = 'default'
        background.style.pointerEvents = 'none'
      } else {
        background.style = ''
        text.style = ''
        background.onclick = function (event) {
          placeholder.scrollIntoView()
          check()
        }
      }
    }
    function hover (event) { event.currentTarget.classList.toggle(css.hover) }
    function minimize (event) {
      event.preventDefault()
      event.stopPropagation()
      if (event.button === 0) {
        var classList = self._view.icon.classList
        classList.toggle('fa-angle-double-down')
        classList.toggle('fa-angle-double-up')
        self.event.trigger('resize', [])
      }
    }
    var filtertimeout = null
    function filter (event) {
      if (filtertimeout) {
        clearTimeout(filtertimeout)
      }
      filtertimeout = setTimeout(() => {
        self.updateJournal({ type: 'search', value: document.querySelector('.' + event.target.className).value })
      }, 500)
    }
    function clear (event) {
      refocus()
      self._view.journal.innerHTML = ''
    }
    // ----------------- resizeable ui ---------------
    function mousedown (event) {
      event.preventDefault()
      if (event.which === 1) {
        moveGhostbar(event)
        document.body.appendChild(ghostbar)
        document.addEventListener('mousemove', moveGhostbar)
        document.addEventListener('mouseup', removeGhostbar)
        document.addEventListener('keydown', cancelGhostbar)
      }
    }
    function cancelGhostbar (event) {
      if (event.keyCode === 27) {
        document.body.removeChild(ghostbar)
        document.removeEventListener('mousemove', moveGhostbar)
        document.removeEventListener('mouseup', removeGhostbar)
        document.removeEventListener('keydown', cancelGhostbar)
      }
    }
    function moveGhostbar (event) { // @NOTE HORIZONTAL ghostbar
      ghostbar.style.top = self._api.getPosition(event) + 'px'
    }
    function removeGhostbar (event) {
      if (self._view.icon.classList.contains('fa-angle-double-up')) {
        self._view.icon.classList.toggle('fa-angle-double-down')
        self._view.icon.classList.toggle('fa-angle-double-up')
      }
      document.body.removeChild(ghostbar)
      document.removeEventListener('mousemove', moveGhostbar)
      document.removeEventListener('mouseup', removeGhostbar)
      document.removeEventListener('keydown', cancelGhostbar)
      self.event.trigger('resize', [self._api.getPosition(event)])
    }

    self._cmdHistory = []
    self._cmdIndex = -1
    self._cmdTemp = ''

    var intro = yo`<div><div> - Welcome to Remix v0.7.5 - </div><br>
                  <div>You can use this terminal for: </div>
                  <ul class=${css2.ul}>
                    <li>Checking transactions details and start debugging.</li>
                    <li>Running JavaScript scripts. The following libraries are accessible:
                      <ul class=${css2.ul}>
                        <li><a target="_blank" href="https://web3js.readthedocs.io/en/1.0/">web3 version 1.0.0</a></li>
                        <li><a target="_blank" href="https://docs.ethers.io/ethers.js/html/">ethers.js</a> </li>
                        <li><a target="_blank" href="https://www.npmjs.com/package/swarmgw">swarmgw</a> </li>
                        <li>compilers - contains currently loaded compiler</li>
                      </ul>
                    </li>
                    <li>Executing common command to interact with the Remix interface (see list of commands above). Note that these commands can also be included and run from a JavaScript script.</li>
                    <li>Use exports/.register(key, obj)/.remove(key)/.clear() to register and reuse object across script executions.</li>
                  </ul>
                  </div>`

    self._shell('remix.help()', self.commands, () => {})
    self.commands.html(intro)
    return self._view.el

    function change (event) {
      handleAutoComplete(event)
      if (self._view.input.innerText.length === 0) self._view.input.innerText += '\n'
      if (event.which === 13) {
        if (event.ctrlKey) { // <ctrl+enter>
          self._view.input.innerText += '\n'
          putCursor2End(self._view.input)
          self.scroll2bottom()
          removeAutoComplete()
        } else { // <enter>
          self._cmdIndex = -1
          self._cmdTemp = ''
          event.preventDefault()
          var script = self._view.input.innerText.trim()
          self._view.input.innerText = '\n'
          if (script.length) {
            self._cmdHistory.unshift(script)
            self.commands.script(script)
          }
          removeAutoComplete()
        }
      } else if (event.which === 38) { // <arrowUp>
        if (self._components.autoCompletePopup.data._options.length > self._components.autoCompletePopup._elementsToShow) {
          self._components.autoCompletePopup._view.autoComplete.children[1].children[0].onclick(event)
        } else {
          var len = self._cmdHistory.length
          if (len === 0) return event.preventDefault()
          if (self._cmdHistory.length - 1 > self._cmdIndex) {
            self._cmdIndex++
          }
          self._view.input.innerText = self._cmdHistory[self._cmdIndex]
          putCursor2End(self._view.input)
          self.scroll2bottom()
        }
      } else if (event.which === 40) { // <arrowDown>
        if (self._components.autoCompletePopup.data._options.length > self._components.autoCompletePopup._elementsToShow) {
          self._components.autoCompletePopup._view.autoComplete.children[1].children[1].onclick(event)
        } else {
          if (self._cmdIndex > -1) {
            self._cmdIndex--
          }
          self._view.input.innerText = self._cmdIndex >= 0 ? self._cmdHistory[self._cmdIndex] : self._cmdTemp
          putCursor2End(self._view.input)
          self.scroll2bottom()
        }
      } else {
        self._cmdTemp = self._view.input.innerText
      }
    }
    function putCursor2End (editable) {
      var range = document.createRange()
      range.selectNode(editable)
      var child = editable
      var chars

      while (child) {
        if (child.lastChild) child = child.lastChild
        else break
        if (child.nodeType === Node.TEXT_NODE) {
          chars = child.textContent.length
        } else {
          chars = child.innerHTML.length
        }
      }

      range.setEnd(child, chars)
      var toStart = true
      var toEnd = !toStart
      range.collapse(toEnd)

      var sel = window.getSelection()
      sel.removeAllRanges()
      sel.addRange(range)

      editable.focus()
    }
    function handleAutoComplete (event) {
      if (event.which === 9) {
        event.preventDefault()
        let textList = self._view.input.innerText.split(' ')
        let autoCompleteInput = textList.length > 1 ? textList[textList.length - 1] : textList[0]
        if (self._view.input.innerText.length >= 2) {
          self._components.autoCompletePopup.data._options = []
          Commands.allPrograms.forEach(item => {
            if (Object.keys(item)[0].substring(0, Object.keys(item)[0].length - 1).includes(autoCompleteInput.trim())) {
              self._components.autoCompletePopup.data._options.push(item)
            } else if (autoCompleteInput.trim().includes(Object.keys(item)[0]) || (Object.keys(item)[0] === autoCompleteInput.trim())) {
              Commands.allCommands.forEach(item => {
                if (Object.keys(item)[0].includes(autoCompleteInput.trim())) {
                  self._components.autoCompletePopup.data._options.push(item)
                }
              })
            }
          })
        }
        if (self._components.autoCompletePopup.data._options.length === 1) {
          textList.pop()
          textList.push(Object.keys(self._components.autoCompletePopup.data._options[0])[0])
          self._view.input.innerText = `${textList}`.replace(/,/g, ' ')
          self._components.autoCompletePopup.data._options = []
          putCursor2End(self._view.input)
        }
      }
      if (event.which === 27 || event.which === 8 || event.which === 46) {
        self._components.autoCompletePopup.data._options = []
        self._components.autoCompletePopup._startingElement = 0
      }
      yo.update(self._view.autoCompletePopup, self._components.autoCompletePopup.render())
    }
    function removeAutoComplete () {
      self._components.autoCompletePopup.data._options = []
      self._components.autoCompletePopup._startingElement = 0
      self._components.autoCompletePopup._removePopUp()
      yo.update(self._view.autoCompletePopup, self._components.autoCompletePopup.render())
    }
  }
  updateJournal (filterEvent) {
    var self = this
    var commands = self.data.activeFilters.commands
    var value = filterEvent.value
    if (filterEvent.type === 'select') {
      commands[value] = true
      if (!self._INDEX.commandsMain[value]) return
      self._INDEX.commandsMain[value].forEach(item => {
        item.root.steps.forEach(item => { self._JOURNAL[item.gidx] = item })
        self._JOURNAL[item.gidx] = item
      })
    } else if (filterEvent.type === 'deselect') {
      commands[value] = false
      if (!self._INDEX.commandsMain[value]) return
      self._INDEX.commandsMain[value].forEach(item => {
        item.root.steps.forEach(item => { self._JOURNAL[item.gidx] = undefined })
        self._JOURNAL[item.gidx] = undefined
      })
    } else if (filterEvent.type === 'search') {
      if (value !== self.data.activeFilters.input) {
        var query = self.data.activeFilters.input = value
        var items = self._JOURNAL
        for (var gidx = 0, len = items.length; gidx < len; gidx++) {
          var item = items[gidx]
          if (item && self.data.filterFns[item.cmd]) {
            var show = query.length ? self.data.filterFns[item.cmd](item.args, query) : true
            item.hide = !show
          }
        }
      }
    }
    var df = document.createDocumentFragment()
    self._JOURNAL.forEach(item => {
      if (item && item.el && !item.hide) df.appendChild(item.el)
    })
    requestAnimationFrame(function updateDOM () {
      self._view.journal.innerHTML = ''
      self._view.journal.appendChild(df)
    })
  }
  _appendItem (item) {
    var self = this
    var { el, gidx } = item
    self._JOURNAL[gidx] = item
    if (!self._jobs.length) {
      requestAnimationFrame(function updateTerminal () {
        self._jobs.forEach(el => self._view.journal.appendChild(el))
        self.scroll2bottom()
        self._jobs = []
      })
    }
    self._jobs.push(el)
  }
  scroll2bottom () {
    var self = this
    setTimeout(function () {
      self._view.term.scrollTop = self._view.term.scrollHeight
    }, 0)
  }
  _blocksRenderer (mode) {
    if (mode === 'html') {
      return function logger (args, scopedCommands, append) {
        if (args.length) append(args[0])
      }
    }
    mode = { log: styles.terminal.text_RegularLog, info: styles.terminal.text_InfoLog, warn: styles.terminal.text_WarnLog, error: styles.terminal.text_ErrorLog }[mode] // defaults
    if (mode) {
      return function logger (args, scopedCommands, append) {
        var types = args.map(type)
        var values = javascriptserialize.apply(null, args).map(function (val, idx) {
          if (typeof args[idx] === 'string') val = args[idx]
          if (types[idx] === 'element') val = jsbeautify.html(val)
          return val
        })
        append(yo`<span style="color: ${mode};">${values}</span>`)
      }
    } else {
      throw new Error('mode is not supported')
    }
  }
  _scopeCommands (append) {
    var self = this
    var scopedCommands = {}
    Object.keys(self.commands).forEach(function makeScopedCommand (cmd) {
      var command = self._commands[cmd]
      scopedCommands[cmd] = function _command () {
        var args = [...arguments]
        command(args, scopedCommands, el => append(cmd, args, blockify(el)))
      }
    })
    return scopedCommands
  }
  registerFilter (commandName, filterFn) {
    this.data.filterFns[commandName] = filterFn
  }
  registerCommand (name, command, opts) {
    var self = this
    name = String(name)
    if (self._commands[name]) throw new Error(`command "${name}" exists already`)
    if (typeof command !== 'function') throw new Error(`invalid command: ${command}`)
    self._commands[name] = command
    self._INDEX.commands[name] = []
    self._INDEX.commandsMain[name] = []
    self.commands[name] = function _command () {
      var args = [...arguments]
      var steps = []
      var root = { steps, cmd: name }
      var ITEM = { root, cmd: name }
      root.gidx = self._INDEX.allMain.push(ITEM) - 1
      root.idx = self._INDEX.commandsMain[name].push(ITEM) - 1
      function append (cmd, params, el) {
        var item
        if (cmd) { // subcommand
          item = { el, cmd, root }
        } else { // command
          item = ITEM
          item.el = el
          cmd = name
        }
        item.gidx = self._INDEX.all.push(item) - 1
        item.idx = self._INDEX.commands[cmd].push(item) - 1
        item.step = steps.push(item) - 1
        item.args = params
        self._appendItem(item)
      }
      var scopedCommands = self._scopeCommands(append)
      command(args, scopedCommands, el => append(null, args, blockify(el)))
    }
    var help = typeof command.help === 'string' ? command.help : [
      '// no help available for:',
      `terminal.commands.${name}(...)`
    ].join('\n')
    self.commands[name].toString = _ => { return help }
    self.commands[name].help = help
    self.data.activeFilters.commands[name] = opts && opts.activate
    if (opts.filterFn) {
      self.registerFilter(name, opts.filterFn)
    }
    return self.commands[name]
  }
  _shell (script, scopedCommands, done) { // default shell
    if (script.indexOf('remix:') === 0) {
      return done(null, 'This type of command has been deprecated and is not functionning anymore. Please run remix.help() to list available commands.')
    }
    var self = this
    var context = domTerminalFeatures(self, scopedCommands)
    try {
      var cmds = vm.createContext(Object.assign(self._jsSandboxContext, context, self._jsSandboxRegistered))
      var result = vm.runInContext(script, cmds)
      self._jsSandboxContext = Object.assign(cmds, context)
      done(null, result)
    } catch (error) {
      done(error.message)
    }
  }
}

function domTerminalFeatures (self, scopedCommands) {
  return {
    compilers: self._opts.compilers,
    swarmgw,
    ethers,
    remix: self._components.cmdInterpreter,
    web3: new Web3(executionContext.web3().currentProvider),
    console: {
      log: function () { scopedCommands.log.apply(scopedCommands, arguments) },
      info: function () { scopedCommands.info.apply(scopedCommands, arguments) },
      warn: function () { scopedCommands.warn.apply(scopedCommands, arguments) },
      error: function () { scopedCommands.error.apply(scopedCommands, arguments) }
    },
    setTimeout: (fn, time) => {
      return setTimeout(() => { self._shell('(' + fn.toString() + ')()', scopedCommands, () => {}) }, time)
    },
    setInterval: (fn, time) => {
      return setInterval(() => { self._shell('(' + fn.toString() + ')()', scopedCommands, () => {}) }, time)
    },
    clearTimeout: clearTimeout,
    clearInterval: clearInterval,
    exports: {
      register: (key, obj) => { self._jsSandboxRegistered[key] = obj },
      remove: (key) => { delete self._jsSandboxRegistered[key] },
      clear: () => { self._jsSandboxRegistered = {} }
    }
  }
}

function blockify (el) { return yo`<div class=${css.block}>${el}</div>` }

module.exports = Terminal
