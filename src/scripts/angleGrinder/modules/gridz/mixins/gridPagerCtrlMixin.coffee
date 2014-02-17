mixin = angular.module("angleGrinder.gridz")

mixin.controller "gridPagerCtrlMixin", [
  "$log", "$scope", "$parse", "$location", "gridName", "currentId", "path"
  ($log, $scope, $parse, $location, gridName, currentId, path) ->

    currIdGetter = $parse(currentId)
    currIdSetter = currIdGetter.assign

    # watch for the current id changes
    $scope.$watch currentId, (id, oldId) ->
      return unless id?
      return if id is oldId

      $location.path path.replace(":id", id)

    # retrieve row ids on the current grid view
    getGridIds = ->
      grid = $parse(gridName)($scope)
      grid.getIds()

    # load the previous page and yields row ids
    prevGridPage = (callback) ->
      grid = $parse(gridName)($scope)

      grid.prevPage ->
        ids = getGridIds()
        $log.debug "[agGrid] previous page was loaded", ids
        callback(ids)

    # load the next page and yields new ids
    nextGridPage = (callback) ->
      grid = $parse(gridName)($scope)

      grid.nextPage ->
        ids = getGridIds()
        $log.debug "[agGrid] next page was loaded", ids
        callback(ids)

    # get the current state
    getCurrent = ->
      ids = getGridIds()
      [ids, ids.indexOf(currIdGetter($scope).toString())]

    @prevRow = ->
      [ids, indx] = getCurrent()

      if indx > 0
        # get the previous id from the cached array of row ids
        currIdSetter $scope, ids[indx - 1]
      else
        # load the previos page and get the last id
        prevGridPage (ids) -> currIdSetter $scope, ids[ids.length - 1]

    @nextRow = ->
      [ids, indx] = getCurrent()

      if indx < ids.length - 1
        # get the next id from the cached array of row ids
        currIdSetter $scope, ids[indx + 1]
      else
        # load the next page and get the first id
        nextGridPage (ids) -> currIdSetter $scope, ids[0]

    return this
]
