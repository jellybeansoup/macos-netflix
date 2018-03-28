;(function(undefined){

	'use strict';
	
	var jellystyle = window.jellystyle = {
		mutationObservers: {}
	};

	jellystyle.mutationCallback = function(mutation) {
		console.log("mutationCallback", mutation);
		
		var message = {
			hasHeader: false,
			controlsVisible: false,
			overlayVisible: false,
			playerClass: null
		};
		
		var pinningHeader = document.getElementsByClassName("pinning-header-container").item(0);
		var loginHeader = document.getElementsByClassName("login-header").item(0);
		message.hasHeader = pinningHeader !== null || loginHeader !== null;
		
		window.jellystyle.addPaddingToElements();
		
		var player = document.getElementsByClassName("nf-player-container").item(0);
		if (player !== null && player.className.match(/\bdefaultExperience\b/) !== null) {
			message.controlsVisible = player.className.match(/\bactive\b/) !== null;
  			message.overlayVisible = !message.controlsVisible && player.className.match(/\binactive\b/) === null;
			message.playerClass = player.className;

			jellystyle.startObserving("player", player, { attributes: true, attributeFilter: ["class"] });
		}
		
		window.webkit.messageHandlers.jellystyle.postMessage(message);
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
