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
		
		var header = document.getElementsByClassName("pinning-header-container").item(0);
		if (header !== null) {
			message.hasHeader = true;
			header.style.paddingTop = "22px";
		}
		
		var topLeftControls = document.getElementsByClassName("top-left-controls").item(0);
		if (topLeftControls !== null) {
			topLeftControls.style.paddingTop = "22px";
		}
		
		var player = document.getElementsByClassName("nf-player-container").item(0);
		if (player !== null && player.className.match(/\bdefaultExperience\b/) !== null) {
			message.controlsVisible = player.className.match(/\bactive\b/) !== null;
  			message.overlayVisible = !message.controlsVisible && player.className.match(/\binactive\b/) === null;
			message.playerClass = player.className;

			jellystyle.startObserving("player", player, { attributes: true, attributeFilter: ["class"] });
		}
		
		window.webkit.messageHandlers.jellystyle.postMessage(message);
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

})();
