spinner = angular.module("angleGrinder.spinner", ["angleGrinder.common"])

###
Use css to set the spinner annimation image:
```
  li.spinner i.spin:before {
    content: url('/img/ajax-loader.gif');
  }
```
###
spinner.directive "agSpinner", ->
  replace: true
  restrict: "E"
  template: """
    <li class="spinner">
      <a href="#"><i ng-class="{spin: showSpinner()}"></i></a>
    </li>
  """
  controller: [
    "$scope", "pendingRequests",
    ($scope, pendingRequests) ->
      $scope.showSpinner = -> pendingRequests.any()
  ]
