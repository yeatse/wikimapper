/**
 * Content script for Safari compatibility
 * Detects navigation types that Safari's webNavigation API doesn't provide
 */

(function() {
  'use strict';

  // Throttle function to prevent excessive messages
  function throttle(func, wait) {
    let timeout;
    return function executedFunction(...args) {
      const later = () => {
        clearTimeout(timeout);
        func(...args);
      };
      clearTimeout(timeout);
      timeout = setTimeout(later, wait);
    };
  }

  // Send navigation type to background script
  function sendNavType(navType, url = window.location.href) {
    try {
      browser.runtime.sendMessage({
        navType,
        url,
        timestamp: Date.now()
      });
    } catch (error) {
      console.error('WikiMapper: Error sending nav type:', error);
    }
  }

  // Send navigation qualifier to background script
  function sendNavQualifier(navQualifier, url = window.location.href) {
    try {
      browser.runtime.sendMessage({
        navQualifier,
        url,
        timestamp: Date.now()
      });
    } catch (error) {
      console.error('WikiMapper: Error sending nav qualifier:', error);
    }
  }

  // Throttled version to prevent spam
  const throttledSendNavType = throttle(sendNavType, 100);
  const throttledSendNavQualifier = throttle(sendNavQualifier, 100);

  // Detect link clicks
  document.addEventListener('click', function(event) {
    const link = event.target.closest('a[href]');
    if (link && link.href) {
      // Check if it's a same-origin link or external
      try {
        const linkUrl = new URL(link.href);

        // Only track Wikipedia/Wiktionary links
        if (linkUrl.hostname.includes('wikipedia.org') || linkUrl.hostname.includes('wiktionary.org')) {
          console.log('WikiMapper: Link click detected', link.href);
          throttledSendNavType('link', link.href);
        }
      } catch (error) {
        // Invalid URL, skip
      }
    }
  }, true); // Use capture to get the event before any preventDefault

  // Detect form submissions
  document.addEventListener('submit', function(event) {
    const form = event.target;
    if (form && form.tagName === 'FORM') {
      console.log('WikiMapper: Form submission detected');
      throttledSendNavType('form_submit');
    }
  }, true);

  const navEntry = performance.getEntriesByType('navigation')[0];
  const isRefresh = navEntry && navEntry.type === 'reload';
  const isForwardBack = navEntry && navEntry.type === 'back_forward';
  if (isRefresh) {
    console.log('WikiMapper: Page refresh detected - background will skip recording');
    throttledSendNavType('refresh');
  } else if (isForwardBack) {
    console.log('WikiMapper: Forward/back navigation detected - sending qualifier to background');
    throttledSendNavQualifier('forward_back');
  }

  console.log('WikiMapper: Content script loaded for navigation detection');

  // Detect forward/back navigation when the page is restored from the
  // back‑forward cache (BFCache). In Safari and many modern browsers,
  // pages restored from BFCache do **not** re‑execute the content script,
  // so our initial PerformanceNavigationTiming check only runs once.
  window.addEventListener('pageshow', (event) => {
    // `event.persisted === true` indicates the page was restored from
    // BFCache. Combine this with a fresh PerformanceNavigationTiming check
    // for maximum browser coverage.
    const navEntry = performance.getEntriesByType('navigation')[0];
    const cameFromBFCache =
      (navEntry && navEntry.type === 'back_forward') || event.persisted;

    if (cameFromBFCache) {
      console.log('WikiMapper: pageshow forward/back navigation detected');
      throttledSendNavQualifier('forward_back');
    }
  });

  // Send a test message to verify content script is working
  try {
    browser.runtime.sendMessage({
      type: 'content_script_loaded',
      url: window.location.href,
      timestamp: Date.now()
    });
  } catch (error) {
    console.error('WikiMapper: Failed to send test message:', error);
  }
})();
