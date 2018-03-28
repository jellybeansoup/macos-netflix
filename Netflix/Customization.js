;(function(undefined){

	'use strict';
	
	var jellystyle = window.jellystyle = {
		mutationObservers: {}
	};

	jellystyle.mutationCallback = function(mutation) {
		console.log("mutationCallback", mutation);
		
		var message = {
			hasHeader: false,
			hasSearch: window.jellystyle.hasSearch(),
			controlsVisible: false,
			overlayVisible: false,
			playerClass: null,
			videoSize: null
		};
		
		var pinningHeader = document.getElementsByClassName("pinning-header-container").item(0);
		var loginHeader = document.getElementsByClassName("login-header").item(0);
		message.hasHeader = pinningHeader !== null || loginHeader !== null;
		
		window.jellystyle.addPaddingToElements();
		
		var player = window.jellystyle.playerContainer();
		if (player !== null) {
			message.controlsVisible = player.className.match(/\bactive\b/) !== null;
  			message.overlayVisible = !message.controlsVisible && player.className.match(/\binactive\b/) === null;
			message.playerClass = player.className;

			var video = player.getElementsByTagName("video").item(0)
			if (video !== null) {
				message.videoSize = [video.videoWidth, video.videoHeight]; 
			}

			jellystyle.startObserving("player", player, { attributes: true, attributeFilter: ["class"] });
		}
		
		window.webkit.messageHandlers.jellystyle.postMessage(message);
	};
	
	jellystyle.playerContainer = function() {
		var player = document.getElementsByClassName("nf-player-container").item(0);

		if (player === null ) {
			return null;	
		}
		else if (player.getElementsByClassName("controls").length === 0) {
			return null;
		}

		return player
	};
	
	jellystyle.addPaddingToElements = function() {
		var classes = [
			"pinning-header-container",
			"signupBasicHeader",
			"login-header",
			"login-body",
			"top-left-controls",
		];

		for(var i in classes) {
			var elementClass = classes[i];
			var element = document.getElementsByClassName(elementClass).item(0)
			
			if (element === null) {
				continue;
			}

			element.style.paddingTop = "22px";
		}
	};

	jellystyle.hasSearch = function() {
		var searchButton = document.getElementsByClassName("searchTab").item(0);
		if (searchButton !== null) {
			return true;
		}
		
		var searchInput = document.getElementsByTagName("input").item(0);
		if (searchInput !== null && searchInput.hasAttribute("data-search-input") && searchInput.attributes["data-search-input"].value === "true") {
			return true;
		}
		
		return false;
	};

	jellystyle.focusSearch = function() {
		var searchButton = document.getElementsByClassName("searchTab").item(0);
		if (searchButton !== null) {
			searchButton.click();
		}
		
		var searchInput = document.getElementsByTagName("input").item(0);
		if (searchInput !== null && searchInput.hasAttribute("data-search-input") && searchInput.attributes["data-search-input"].value === "true") {
			searchInput.focus();			
		}
	};

	jellystyle.startObserving = function(key, element, options) {
		if (jellystyle.mutationObservers[key] !== undefined) {
			return;
		}
	
		var observer = new MutationObserver(jellystyle.mutationCallback);
		observer.observe(element, options);
		jellystyle.mutationObservers[key] = observer;
	};

	jellystyle.stopObserving = function(key, element, options) {
		if (jellystyle.mutationObservers[key] === undefined) {
			return;
		}
	
		jellystyle.mutationObservers[key].disconnect();
		delete jellystyle.mutationObservers[key];
	};

	jellystyle.startObserving("body", document.body, { attributes: true, subtree: true });
	
	// Always run the mutation callback at least once
	jellystyle.mutationCallback(null);

})();
