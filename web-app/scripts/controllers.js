var module = angular.module("admin.controllers", ["admin.services"]);

module.controller("ListCtrl", function ($scope, $rootScope, $routeParams, $location, Grails, Flash, EditDialog) {

  $scope.createDialog = function () {
    $scope.item = new Grails;
    EditDialog.open($scope.editTemplateUrl, $scope.item, true)
  }

  $scope.editDialog = function (id) {
    // clear errors
    $scope.errors = null;
    $scope.dataLoaded = false;

    Grails.get({id: id}, function (item) {
      $scope.item = item;
      $scope.dataLoaded = true;
      EditDialog.open($scope.editTemplateUrl, $scope.item, false)

    }, errorHandler.curry($scope, $location, Flash));

  };

  $scope.quickSearch = function (search) {
    $rootScope.$broadcast("searchUpdated", search)
  }

});

// dialog is the passed in instance from the angualr-ui dialog
module.controller("EditItemController", function ($scope, $rootScope, dialog, item, isCreateNew, Flash) {
  console.log($scope)

  $scope.item = item;
  $scope.isCreateNew = isCreateNew;

  $scope.closeEditDialog = function () {
    dialog.close();
  }

  $scope.save = function (item) {
    console.log("saveOrUpdate " + item)
    $scope.saving = true
    item.$save(function (response) {
      $scope.closeEditDialog()
      $rootScope.$broadcast("itemUpdated", response)
    }, errorHandler.curry($scope, Flash));
  };

});
