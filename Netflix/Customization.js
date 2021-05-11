;(function(undefined){

	'use strict';

	var jellystyle = window.jellystyle = {
		mutationObservers: {}
	};

	jellystyle.mutationCallback = function(mutation) {
		var message = {
			hasHeader: false,
			hasSearch: window.jellystyle.hasSearch(),
			controlsVisible: false,
			overlayVisible: false,
			playerClass: null,
			videoSize: null
		};

		var pinningHeader = document.getElementsByClassName("pinning-header-container").item(0);
		var mainHeader = document.getElementsByClassName("main-header").item(0);
		var memberHeader = document.getElementsByClassName("member-header").item(0);
		var ourStoryHeader = document.getElementsByClassName("our-story-header").item(0);
		var loginHeader = document.getElementsByClassName("login-header").item(0);
		var globalHeader = document.getElementsByClassName("global-header").item(0);
		message.hasHeader = pinningHeader !== null || mainHeader !== null || memberHeader !== null || ourStoryHeader !== null || loginHeader !== null || globalHeader !== null;

		var player = window.jellystyle.playerContainer();
		if (player !== null) {
			message.controlsVisible = player.className.match(/\bactive\b/) !== null;
				message.overlayVisible = !message.controlsVisible && player.className.match(/\binactive\b/) === null;
			message.playerClass = player.className;

			var video = player.getElementsByTagName("video").item(0);
			if (video !== null) {
				message.videoSize = [video.videoWidth, video.videoHeight];

				jellystyle.updateVideoElement(video);
			} else {
				jellystyle.updateVideoElement(null);
			}

			if (!jellystyle.isObserving("player", player)) {
				// Dispatch an event to get the full screen icon to reflect current status
				document.dispatchEvent(new Event("fullscreenchange"))
			}

			jellystyle.startObserving("player", player, { attributes: true, attributeFilter: ["class"] });
		}

		// Refresh any insets, just in case we've modified the document
		jellystyle.setTitleViewInset(jellystyle.currentTitleViewInset);

		window.webkit.messageHandlers.jellystyle.postMessage(message);
	};

	jellystyle.playerContainer = function() {
		var player = document.getElementsByClassName("nf-player-container").item(0);

		if (player === null ) {
			return null;
		}

		var potentialControlElements = [
			player.getElementsByClassName("controls"),
			player.getElementsByClassName("PlayerControlsNeo__all-controls"),
		]

		for(var i in potentialControlElements) {
			var potentialControlElement = potentialControlElements[i];

			if (potentialControlElement.length >= 1) {
				return player
			}
		}

		return null;
	};

	jellystyle.currentTitleViewInset = null;

	jellystyle.setTitleViewInset = function(value) {
		var classNames = {
			"main-header": "marginTop",
			"member-header": "marginTop",
			"our-story-header": "marginTop",
			"login-header": "marginTop",
			"login-body": "paddingTop",
			"global-header": "paddingTop",
			"top-left-controls": "paddingTop",
		};

		for(const [className, propertyName] of Object.entries(classNames)) {
			//var propertyName = classNames[className];
			var element = document.getElementsByClassName(className).item(0)

			if (element === null) {
				continue;
			}

			element.style[propertyName] = value;
		}

		jellystyle.currentTitleViewInset = value;
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
		if (jellystyle.isObserving(key, element)) {
			return;
		}

		var observer = new MutationObserver(jellystyle.mutationCallback);
		observer.observe(element, options);
		jellystyle.mutationObservers[key] = [observer, element];
	};

	jellystyle.isObserving = function(key, element) {
		if (jellystyle.mutationObservers[key] === undefined) {
			return false;
		}

		var observer = jellystyle.mutationObservers[key];

		if (observer[1] !== element) {
			return false;
		}

		return true;
	};

	jellystyle.stopObserving = function(key, element, options) {
		if (!jellystyle.isObserving(key, element)) {
			return;
		}

		jellystyle.mutationObservers[key][0].disconnect();
		delete jellystyle.mutationObservers[key];
	};

	// MARK: Console override

	console.log = function() {
		var message = Array.from(arguments).join(" ");
		window.webkit.messageHandlers.jellystyle.postMessage(message);
	}

	// MARK: Full screen mode

	HTMLDocument.prototype.fullscreenEnabled = true;

	HTMLElement.prototype.requestFullscreen = function() {
		window.jellystyle.pendingFullScreenElement = this;
		window.webkit.messageHandlers.requestFullscreen.postMessage(true);
		return new Promise(function(resolve) { resolve(); });
	};

	HTMLDocument.prototype.exitFullscreen = function() {
		window.webkit.messageHandlers.requestFullscreen.postMessage(false);
		return new Promise(function(resolve) { resolve(); });
	};

	jellystyle.pendingFullScreenElement = null;

	jellystyle.windowDidEnterFullScreen = function(success) {
		if (success) {
			document.fullscreen = true;
			document.fullscreenElement = window.jellystyle.pendingFullScreenElement || document.body;
			document.dispatchEvent(new Event("fullscreenchange"))
		}
		else {
			document.dispatchEvent(new Event("fullscreenerror"))
		}

		window.jellystyle.pendingFullScreenElement = null;
	};

	jellystyle.windowDidExitFullScreen = function(success) {
		if (success) {
			document.fullscreen = false;
			document.fullscreenElement = null;
			document.dispatchEvent(new Event("fullscreenchange"))
		}
		else {
			document.dispatchEvent(new Event("fullscreenerror"))
		}
	};

	// MARK: Playback control

	var setVideoStatus = function(status) {
		window.webkit.messageHandlers.playback.postMessage({
			status: status
		});
	};

	var onVideoPlay = setVideoStatus.bind(null, "playing");
	var onVideoPause = setVideoStatus.bind(null, "paused");

	jellystyle.updateVideoElement = function(video) {
		if ((jellystyle.videoElement || null) === (video || null)) {
			return;
		}

		if (!video) {
			setVideoStatus("none");
			return;
		}

		if (jellystyle.videoElement) {
			jellystyle.videoElement.removeEventListener("play", onVideoPlay);
			jellystyle.videoElement.removeEventListener("pause", onVideoPause);
		}

		setVideoStatus(video.paused ? "paused" : "playing");

		video.addEventListener("play", onVideoPlay);
		video.addEventListener("pause", onVideoPause);

		jellystyle.videoElement = video;
	};

	jellystyle.resume = function() {
		var video = window.jellystyle.videoElement;
		if (video) {
			video.play();
		}
	};

	jellystyle.pause = function() {
		var video = window.jellystyle.videoElement;
		if (video) {
			video.pause();
		}
	};

	// MARK: Other utilities

	jellystyle.setControlsVisibility = function(flag) {
		var controlsElement = document.getElementsByClassName("PlayerControlsNeo__layout").item(0);
		if (!controlsElement) {
			return;
		}

		if (flag) {
			controlsElement.classList.add('PlayerControlsNeo__layout--active');
			controlsElement.classList.remove('PlayerControlsNeo__layout--inactive')
		} else {
			controlsElement.classList.add('PlayerControlsNeo__layout--inactive');
			controlsElement.classList.remove('PlayerControlsNeo__layout--active')
		}
	};


	jellystyle.startObserving("body", document.body, { attributes: true, subtree: true });

	// Always run the mutation callback at least once
	jellystyle.mutationCallback(null);


})();
