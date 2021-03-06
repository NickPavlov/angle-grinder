describe "module: angleGrinder.common directive: agSideMenu", ->
  beforeEach module "angleGrinder.common"

  element = null
  $scope = null
  ngModel = null

  beforeEach module "angleGrinder", ($provide) ->
    $provide.decorator "$window", ($delegate) ->
      $delegate

    return

  beforeEach inject ($rootScope, $compile) ->
    $scope = $rootScope.$new()

    element = angular.element """
       <ul offset="40" ag-side-menu id="test">
      <li><a><i class="icon-chevron-right"></i> test1</a></li>
      <li><a><i class="icon-chevron-right"></i> test2</a></li>
    </ul>
      """
    $compile(element)($scope)
    $scope.$digest()

  describe "check scrolling", ->
    it "window scroll", ->
      $(window).trigger("scroll")
      element.find('#test').triggerHandler('scroll')
      expect(element.css("position")).eq 'relative'
