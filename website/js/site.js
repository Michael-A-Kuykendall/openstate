/* OpenState site behaviour: demo recordings and the install copy button.
 * The page is complete without this file: recordings fall back to posters
 * with native controls, and the install command stays selectable text. */
(function () {
  "use strict";
  var doc = document;
  doc.documentElement.classList.add("js");

  var reduceMotion = !!(window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches);
  var clips = Array.prototype.slice.call(doc.querySelectorAll(".os-clip"));
  var tabs = Array.prototype.slice.call(doc.querySelectorAll(".os-clip-tab"));
  var current = clips[0] || null;
  var inView = false;

  function videosOf(clip) {
    return Array.prototype.slice.call(clip.querySelectorAll("video"));
  }

  function shown(video) {
    return video.offsetParent !== null;
  }

  // Play only the recording the reader can see; pause everything else.
  function sync() {
    clips.forEach(function (clip) {
      videosOf(clip).forEach(function (video) {
        var play = !reduceMotion && inView && clip === current && shown(video);
        if (!play) {
          video.pause();
          return;
        }
        var started = video.play();
        if (started && typeof started.catch === "function") {
          started.catch(function () {
            video.controls = true;
          });
        }
      });
    });
  }

  function select(index) {
    current = clips[index];
    clips.forEach(function (clip, i) {
      clip.hidden = i !== index;
    });
    tabs.forEach(function (tab, i) {
      tab.setAttribute("aria-pressed", i === index ? "true" : "false");
    });
    if (!reduceMotion) {
      videosOf(current).forEach(function (video) {
        if (video.readyState > 0) {
          video.currentTime = 0;
        }
      });
    }
    sync();
  }

  if (clips.length) {
    if (!reduceMotion) {
      clips.forEach(function (clip) {
        videosOf(clip).forEach(function (video) {
          video.controls = false;
        });
      });
    }
    tabs.forEach(function (tab, i) {
      tab.addEventListener("click", function () {
        select(i);
      });
    });
    select(0);

    var stage = doc.getElementById("demo");
    if (stage && "IntersectionObserver" in window) {
      new IntersectionObserver(function (entries) {
        inView = entries[entries.length - 1].isIntersecting;
        sync();
      }, { threshold: 0.15 }).observe(stage);
    } else {
      inView = true;
      sync();
    }
    window.addEventListener("resize", sync);
  }

  // Install command: copy to the clipboard, or select it when that is refused.
  Array.prototype.slice.call(doc.querySelectorAll(".os-copy")).forEach(function (button) {
    var target = doc.getElementById(button.getAttribute("data-copy"));
    if (!target) {
      return;
    }
    var label = button.textContent;
    function say(text) {
      button.textContent = text;
      window.setTimeout(function () {
        button.textContent = label;
      }, 1600);
    }
    function selectText() {
      var range = doc.createRange();
      range.selectNodeContents(target);
      var selection = window.getSelection();
      selection.removeAllRanges();
      selection.addRange(range);
      say("Selected");
    }
    button.addEventListener("click", function () {
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(target.textContent.trim()).then(function () {
          say("Copied");
        }, selectText);
      } else {
        selectText();
      }
    });
  });
})();
