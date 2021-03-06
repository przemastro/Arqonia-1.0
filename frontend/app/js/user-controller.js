'use strict';


 angular.module('astroApp.controller', ['ngResource', 'ngAnimate', 'ui.bootstrap', 'smart-table',
 'angularModalService', 'angularSpinner', 'nvd3', 'ngCookies', 'ngAnimate', 'ngSanitize', 'ngCsv', 'angular-bind-html-compile']);

    // Register environment in AngularJS as constant
    astroApp.constant('__env', __env);


//----------------------------------------------------------Logout-------------------------------------------------------

    //logoutCtrl
	astroApp.controller('logoutCtrl', ['$rootScope', 'login', '$cookies', '$uibModal', 'updateUser',
	                          function ($scope, Login, $cookies, $uibModal, UpdateUser) {
   		  UpdateUser.update({email:$cookies.get('email'),sessionId:$cookies.get('sessionID')}, function(response){
   		  $scope.message = response.message;
   		  });
	   //put the cookie down
	   $scope.message = 'Logout';
	   $cookies.remove("cook");
	   $cookies.remove("admin");
	   $cookies.remove("name");
	   $cookies.remove("email");
	   $cookies.remove("sessionID");
	   $cookies.remove("numberOfDarkFilesUploaded");
	   $cookies.remove("numberOfFlatFilesUploaded");
	   $cookies.remove("numberOfRawFilesUploaded");
	   $cookies.remove("numberOfBiasFilesUploaded");
	   $cookies.remove("numberOfProcessedFiles");
	}]);

    astroApp.controller('goodbyeCtrl', ['$rootScope', 'usSpinnerService', 'login', '$cookies', '$location', '$timeout',
    function ($scope, usSpinnerService, Login, $cookies, $location, $timeout) {

       //Firstly we need to kill all active modals
       $('.modal-content > .ng-scope').each(function()
       {
           try
           {
               $(this).scope().$dismiss();
           }
           catch(_) {}
       });

       //Set flags
       $scope.isUserLoggedIn = false;
       $scope.isAdminLoggedIn = false;
             if (!$scope.spinneractive) {
               usSpinnerService.spin('spinner-1');
             };
             $scope.spinneractive = false;
             usSpinnerService.stop('spinner-1');
       $location.path("main");
      	           $scope.successTextAlert = "Logout successful.";
                       $scope.showSuccessAlert = true;
                       // switch flag
                       $scope.switchBool = function (value) {
                           $scope[value] = !$scope[value];
                       };

                    $timeout(function(){
                       $scope.showSuccessAlert = false;
                       }, 5000);
    }]);


//-----------------------------------------------------------Home-------------------------------------------------------

    //mainCtrl
	astroApp.controller('mainCtrl', ['$rootScope', '$scope', 'login', '$cookies', 'getStatistics', '$uibModal', 'subscribe', '$window', '$timeout',
	                       function ($rootScope, $scope, Login, $cookies, Statistics, $uibModal, Subscribe, $window, $timeout) {
	   $rootScope.isUserLoggedIn = $cookies.get('cook');
	   $rootScope.isAdminLoggedIn = $cookies.get('admin');
	   $rootScope.loggedInUser = $cookies.get('name');
	   $rootScope.sessionID = $cookies.get('sessionID');
	   $rootScope.userAcceptCookies = $cookies.get('allowCookies');
       $scope.Statistics = Statistics.query();


              //Login Modal
              $scope.loginModal = function () {
                     var modalInstance = $uibModal.open({
                     animation: $scope.animationsEnabled,
                     templateUrl: 'loginModalContent.html',
                     controller: 'ModalLoginCtrl',
                   });
              };

              //Register Modal
              $scope.registerModal = function () {
                     var modalInstance = $uibModal.open({
                     animation: $scope.animationsEnabled,
                     templateUrl: 'registerModalContent.html',
                     controller: 'ModalRegisterCtrl',
                   });
              };

              //Edit Profile Modal
              $scope.editProfileModal = function () {
                     var modalInstance = $uibModal.open({
                     animation: $scope.animationsEnabled,
                     templateUrl: 'editProfileModalContent.html',
                     controller: 'ModalEditProfileCtrl',
                   });
              };

       $rootScope.cookiesTextAlert = "This website uses cookies to ensure you get the best experience on our service";
                     $rootScope.showCookiesSuccessAlert = true;
                     $rootScope.switchBoolCookies = function (value) {
                         $rootScope[value] = !$rootScope[value];
                         $cookies.put('allowCookies', true);
                         $rootScope.userAcceptCookies = $cookies.get('allowCookies');
                     };

       $scope.addSubscriber = function(){
      	  Subscribe.save({email:$scope.email}, function(response){
      	  $scope.message = response[Object.keys(response)[0]];
      	           $scope.successTextAlert = "Your email has been added to the subscribe list";
                       $scope.showSuccessAlert = true;
                       // switch flag
                       $scope.switchBool = function (value) {
                           $scope[value] = !$scope[value];
                       };

                    $timeout(function(){
                       $scope.showSuccessAlert = false;
                       }, 5000);
      	  });
       }

	}]);


//----------------------------------------------------------Login-------------------------------------------------------

    //loginCtrl
	astroApp.controller('loginCtrl', function($scope) {
	   $scope.message = 'Login';
	});
	astroApp.controller('ModalLoginCtrl', ['$rootScope', '$scope', '$uibModalInstance', 'usSpinnerService', 'login', '$cookies', '$location', '$uibModal',
	                             function ($rootScope, $scope, $uibModalInstance, usSpinnerService, Login, $cookies, $location, $uibModal) {

      $rootScope.errorFlag = false
      //[Submit]
      $scope.loginUser = function(){
                   if (!$scope.spinneractive) {
                     usSpinnerService.spin('spinner-1');
                   };
          var password = sjcl.encrypt(__env.key, $scope.password)
          var date = new Date();
          $cookies.put('sessionID', date.getTime());

   		  Login.update({email:$scope.email,password:password,sessionId:$cookies.get('sessionID')}, function(response){
   		  $scope.message = response[Object.keys(response)[0]];
          if(($scope.message == "Wrong credentials") || ($scope.message == "User is already logged In")){
   		     $rootScope.isUserLoggedIn = false;
   		     $rootScope.isAdminLoggedIn = false;
   		     $rootScope.errorFlag = true;
   		     $rootScope.errorMessage = $scope.message;
   		        		     $scope.spinneractive = false;
                          usSpinnerService.stop('spinner-1');
   		     }
   		  else if(($scope.message != "Wrong credentials") && ($scope.email != "admin@arqonia.com") && ($scope.message != "User is already logged In")){
             $cookies.put('email', $scope.email);
             $cookies.put('name', $scope.message);
   		     $cookies.put('cook', true);
   		     $cookies.put('admin', false);
   		     $cookies.put('numberOfDarkFilesUploaded', 0);
   		     $cookies.put('numberOfRawFilesUploaded', 0);
   		     $cookies.put('numberOfFlatFilesUploaded', 0);
   		     $cookies.put('numberOfBiasFilesUploaded', 0);
   		     $cookies.put('numberOfProcessedFiles', 0);
   		     $rootScope.isUserLoggedIn = $cookies.get('cook');
   		     $rootScope.isAdminLoggedIn = $cookies.get('admin');
   		     $rootScope.errorFlag = false;
   		     $rootScope.loggedInUser = $cookies.get('name');
   		     $rootScope.sessionID = $cookies.get('sessionID');
   		     $location.path("main");
   		     $scope.spinneractive = false;
             usSpinnerService.stop('spinner-1');
             $uibModalInstance.dismiss();
   		     }
   		  else if(($scope.email == "admin@arqonia.com")) {
   		     $cookies.put('cook', true);
   		     $cookies.put('admin', true);
   		     $cookies.put('name', $scope.message);
   		     $cookies.put('numberOfDarkFilesUploaded', 0);
   		     $cookies.put('numberOfRawFilesUploaded', 0);
   		     $cookies.put('numberOfFlatFilesUploaded', 0);
   		     $cookies.put('numberOfBiasFilesUploaded', 0);
   		     $cookies.put('numberOfProcessedFiles', 0);
   		     $rootScope.isUserLoggedIn = $cookies.get('cook');
   		     $rootScope.isAdminLoggedIn = $cookies.get('admin');
   		     $rootScope.errorFlag = false;
   		     $rootScope.loggedInUser = $cookies.get('name');
   		     $rootScope.sessionID = $cookies.get('sessionID');
   		     //$rootScope.loggedInUser = $scope.message
   		     $location.path("main");
   		     $scope.spinneractive = false;
             usSpinnerService.stop('spinner-1');
             $uibModalInstance.dismiss();
   		     }
   		  });
      };


          //[Cancel]
          $scope.cancel = function () {
            $uibModalInstance.dismiss('cancel');
          };


                  //Reminder Modal
                  $scope.reminderModal = function () {
                       $uibModalInstance.dismiss();
                       var modalInstance = $uibModal.open({
                         animation: $scope.animationsEnabled,
                         templateUrl: 'reminderModalContent.html',
                         controller: 'PasswordReminderCtrl',
                       });
                  };
    }]);


//-----------------------------------------------------Password Reminder------------------------------------------------

    //loginCtrl
	astroApp.controller('reminderCtrl', function($scope) {
	});

   astroApp.controller('PasswordReminderCtrl', ['$rootScope', '$scope', '$uibModalInstance', 'usSpinnerService', 'reminder', '$cookies', '$location',
	                             function ($rootScope, $scope, $uibModalInstance, usSpinnerService, Reminder, $cookies, $location) {

      $rootScope.errorFlag = false
      //[Send]
      $scope.sendPassword = function(){
                   if (!$scope.spinneractive) {
                     usSpinnerService.spin('spinner-1');
                   };
   		  Reminder.save({email:$scope.email, sessionId:$cookies.get('sessionID')}, function(response){
   		     $rootScope.errorFlag = false
   		     $location.path("main");

             $scope.spinneractive = false;
             usSpinnerService.stop('spinner-1');
             $uibModalInstance.dismiss();
   		     })
      };

          //[Cancel]
          $scope.cancel = function () {
            $uibModalInstance.dismiss('cancel');
          };
     }]);


//------------------------------------------------------Edit Profile----------------------------------------------------

	astroApp.controller('editProfileCtrl', function($scope) {
	});

    astroApp.controller('ModalEditProfileCtrl', ['$rootScope', '$scope', '$uibModalInstance', 'usSpinnerService', 'updateProfile', '$cookies', '$location', '$timeout', '$uibModal',
	                             function ($rootScope, $scope, $uibModalInstance, usSpinnerService, UpdateProfile, $cookies, $location, $timeout, $uibModal) {

      $rootScope.errorFlag = false

      $scope.loggedInUser = $cookies.get('name');
      $scope.isUserLoggedIn = $cookies.get('cook');
      $scope.loggedInUserEmail = $cookies.get('email');
      $rootScope.isAdminLoggedIn = $cookies.get('admin');
      $rootScope.sessionID = $cookies.get('sessionID');

      $scope.data = [{name:$scope.loggedInUser, email:$scope.loggedInUserEmail, sessionId:$cookies.get('sessionID')}];
      $scope.changeName = function() {
         $scope.name = this.name;
      };

      $scope.changeEmail = function() {
         $scope.email = this.email;
      };

      $scope.name = $scope.data[0].name;
      $scope.email = $scope.data[0].email;

      //[Submit]
      $scope.updateUser = function(){
             if (!$scope.spinneractive) {
               usSpinnerService.spin('spinner-1');
             };
          var password = sjcl.encrypt(__env.key, $scope.password)

   		  UpdateProfile.update({name:$scope.name,email:$scope.email,password:password,oldEmail:$scope.loggedInUserEmail, sessionId:$cookies.get('sessionID')}, function(response){
   		  $scope.message = response[Object.keys(response)[0]];
          if($scope.message == "User exists"){
   		     $rootScope.errorFlag = true
   		     }
   		  else {


   		     $rootScope.errorFlag = false
   		     $location.path("main");

             $scope.spinneractive = false;
             usSpinnerService.stop('spinner-1');
             $uibModalInstance.dismiss();
      	           $rootScope.successTextAlert = "Your data have been updated. You must re-login in order to continue.";
                       $rootScope.showSuccessAlert = true;
                       // switch flag
                       $rootScope.switchBool = function (value) {
                           $rootScope[value] = !$rootScope[value];
                       };

                    $timeout(function(){
                       $rootScope.showSuccessAlert = false;
                       }, 5000);
   		     }
   		  });
      };

          //[Cancel]
          $scope.cancel = function () {
            $uibModalInstance.dismiss('cancel');
          };

              //Remove Account Modal
              $scope.removeAccountModal = function () {
                     $uibModalInstance.dismiss();
                     var modalInstance = $uibModal.open({
                     animation: $scope.animationsEnabled,
                     templateUrl: 'removeAccountModalContent.html',
                     controller: 'ModalRemoveAccountCtrl',
                   });
              };
     }]);

//------------------------------------------------------Remove Account--------------------------------------------------


   astroApp.controller('ModalRemoveAccountCtrl', ['$rootScope', '$scope', '$uibModalInstance', 'usSpinnerService', 'removeAccount', '$cookies', '$location', '$timeout',
	                             function ($rootScope, $scope, $uibModalInstance, usSpinnerService, RemoveAccount, $cookies, $location, $timeout) {

      $rootScope.errorFlag = false
      $scope.loggedInUser = $cookies.get('name');
      $scope.isUserLoggedIn = $cookies.get('cook');
      $scope.loggedInUserEmail = $cookies.get('email');
      $rootScope.sessionID = $cookies.get('sessionID');
      $rootScope.isAdminLoggedIn = $cookies.get('admin');

      //[Remove]
      $scope.removeAccount = function(){
             if (!$scope.spinneractive) {
               usSpinnerService.spin('spinner-1');
             };
   		     RemoveAccount.update({email:$scope.loggedInUserEmail, sessionId:$cookies.get('sessionID')}, function(response){
                 		     $scope.spinneractive = false;
                           usSpinnerService.stop('spinner-1');

   		     $rootScope.errorFlag = false

             //Firstly we need to kill all active modals
             $('.modal-content > .ng-scope').each(function()
             {
                 try
                 {
                     $(this).scope().$dismiss();
                 }
                 catch(_) {}
             });

             //Set flags
             $rootScope.isUserLoggedIn = false;
             $rootScope.isAdminLoggedIn = false;
             $cookies.remove("cook");
             $cookies.remove("admin");
             $cookies.remove("name");
             $cookies.remove("email");
             $location.path("main");

      	     $rootScope.successTextAlert = "Your account has been soft deleted.";
                 $rootScope.showSuccessAlert = true;
                 // switch flag
                 $rootScope.switchBool = function (value) {
                     $rootScope[value] = !$rootScope[value];
                 };

             $timeout(function(){
                $rootScope.showSuccessAlert = false;
                }, 5000);

   		     })
           };

          //[Cancel]
          $scope.cancel = function () {
            $uibModalInstance.dismiss('cancel');
          };
     }]);

//--------------------------------------------------------Register------------------------------------------------------

	astroApp.controller('registerCtrl', function($scope) {
	   $scope.message = 'Register';
	});

    astroApp.controller('ModalRegisterCtrl', ['$rootScope', '$scope', '$uibModalInstance', 'usSpinnerService', 'register', '$cookies', '$location', '$timeout',
	                             function ($rootScope, $scope, $uibModalInstance, usSpinnerService, Register, $cookies, $location, $timeout) {

      $rootScope.errorFlag = false
      //[Submit]
      $scope.addUser = function(){
                   if (!$scope.spinneractive) {
                     usSpinnerService.spin('spinner-1');
                   };

          var initialNumber = (new Date().getTime()).toString(36)
          var activeNumber = sjcl.encrypt(__env.key, initialNumber)

   		  Register.save({name:$scope.name,email:$scope.email,activeNumber:activeNumber}, function(response){
   		  $scope.message = response[Object.keys(response)[0]];
          if($scope.message == "User exists"){
   		     $rootScope.errorFlag = true
   		        		     $scope.spinneractive = false;
                          usSpinnerService.stop('spinner-1');
   		     }
   		  else {

   		     $rootScope.errorFlag = false
   		     $location.path("main");

             $scope.spinneractive = false;
             usSpinnerService.stop('spinner-1');
             $uibModalInstance.dismiss();
      	           $rootScope.successTextAlert = "You have created new account. We have sent an initial password to the email address you provided.";
                       $rootScope.showSuccessAlert = true;
                       // switch flag
                       $rootScope.switchBool = function (value) {
                           $rootScope[value] = !$rootScope[value];
                       };

                    $timeout(function(){
                       $rootScope.showSuccessAlert = false;
                       }, 5000);

   		     }
   		  });
      };

          //[Cancel]
          $scope.cancel = function () {
            $uibModalInstance.dismiss('cancel');
          };
     }]);