@App.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  stringify = (err) ->
    [err.name, err.message].join(": ")

  class Entities.Project extends Entities.Model
    defaults:
      loading: false

    mutators:
      browserText: ->
        return if not b = @get("browser")

        word = switch @get("browserState")
          when "opened"  then "Running"
          when "opening" then "Opening"
          when "closed"  then "Run"

        [word, b.get("displayName"), b.get("majorVersion")].join(" ")

    initialize: ->
      @setName()

    browserOpening: ->
      @set({
        browserState: "opening"
        browserClickable: false
      })

    browserOpened: ->
      @set({
        browserState: "opened"
        browserClickable: false
      })

    browserClosed: ->
      @set({
        browserState: "closed"
        browserClickable: true
      })

    setBrowser: (browser) ->
      @set "browser", browser

    loaded: ->
      @set("loading", false)

    isLoading: ->
      !!@get("loading")

    setName: ->
      @set name: @getNameFromPath()

    getNameFromPath: ->
      _(@get("path").split("/")).last()

    displayBrowsers: ->
      if b = @get("browsers")
        b.toJSON()
      else
        []

    getBrowsers: (browsers = []) ->
      App.request("new:browser:entities", browsers)

    setConfig: (config) ->
      if b = config.browsers
        config.browsers = @getBrowsers(b)
        config.browser = config.browsers.extractDefaultBrowser()

      @set(config, {silent: true})

      @trigger("opened")

    setError: (err) ->
      if err.portInUse
        @set("portInUse", true)

      @set "error", stringify(err)

    reset: ->
      props = {
        error: null
        portInUse: null
        clientUrl: null
        clientUrlDisplay: null
      }

      @set(props, {silent: true})

      @trigger("rebooted")

  class Entities.ProjectsCollection extends Entities.Collection
    model: Entities.Project

    getProjectByPath: (path) ->
      @findWhere({path: path})

  API =
    getProjects: ->
      projects = new Entities.ProjectsCollection
      App.ipc("get:project:paths").then (paths) ->
        projects.add _(paths).map (path) -> {path: path}
        projects.trigger("fetched")
      projects

  App.reqres.setHandler "project:entities", ->
    API.getProjects()