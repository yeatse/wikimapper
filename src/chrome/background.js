/**
 * Background application.
 * Handles initialization and listening for navigation events.
 */
import Sessions from './session-handler.js';

const triggers = [
  'link',
  'typed',
  'form_submit'
];

// Browser compatibility detection
let isSafari = false;
let hasTransitionSupport = false;

/**
 * Detect Safari and feature support
 */
async function detectBrowserCapabilities() {
  try {
    // Safari >= 17 supports getBrowserInfo
    const info = await browser.runtime.getBrowserInfo();
    isSafari = info?.name === 'Safari';
  } catch (_) {
    // Fallback: Feature detection for older Safari versions
    isSafari = typeof browser?.history?.getVisits !== 'function';
  }

  hasTransitionSupport = !isSafari;
  console.log('WikiMapper: Browser detection', { isSafari, hasTransitionSupport });
}

// Safari timing coordination: cache for webNavigation events waiting for content script messages
const pendingMessageFromWebNavigation = new Map(); // tabId -> { details, timeoutId }
// Cache for content script messages (Safari fallback)
const pendingMessageFromContentScript = new Map(); // tabId -> { type, qualifier, timestamp }

/**
 * Process navigation with type information
 */
async function processNavigationWithInfo(details, navInfo) {
  try {
    if (navInfo?.qualifier === 'forward_back') {
      await Sessions.processForwardBack(details);
    } else if (navInfo?.type) {
      if (triggers.includes(navInfo.type)) {
        await Sessions.processNavigation(details);
      }
    } else {
      // Default fallback: treat as typed navigation
      await Sessions.processNavigation(details);
    }
  } catch (error) {
    console.error('WikiMapper: Error processing navigation with info:', error);
  }
}

/**
 * Consume pending navigation after timeout (Safari fallback)
 */
async function consumePendingNavigation(tabId, defaultType = 'typed') {
  const pendingNav = pendingMessageFromWebNavigation.get(tabId);
  if (pendingNav) {
    console.log('WikiMapper: Consuming pending navigation after timeout', {
      tabId,
      defaultType,
      url: pendingNav.details.url
    });

    clearTimeout(pendingNav.timeoutId);
    await processNavigationWithInfo(pendingNav.details, { type: defaultType });
    pendingMessageFromWebNavigation.delete(tabId);
  }
}

/**
 * Process content script message by checking for pending navigation or caching
 * @param {number} tabId - Tab ID
 * @param {string} messageType - Type of message ('navType' or 'navQualifier')
 * @param {any} messageValue - Value of the message
 * @param {string} url - URL from message
 */
function processContentScriptMessage(tabId, messageType, messageValue, url) {
  console.log(`WikiMapper: ${messageType} from content script`, {
    tabId,
    [messageType]: messageValue,
    url
  });

  // Check if there's a pending navigation waiting for this message
  const pendingNav = pendingMessageFromWebNavigation.get(tabId);
  if (pendingNav) {
    // Found waiting navigation, process immediately
    console.log(`WikiMapper: Processing immediate navigation with ${messageType} info`);
    clearTimeout(pendingNav.timeoutId);

    const navInfo = messageType === 'navType'
      ? { type: messageValue }
      : { qualifier: messageValue };

    processNavigationWithInfo(pendingNav.details, navInfo);
    pendingMessageFromWebNavigation.delete(tabId);
  } else {
    // No waiting navigation, cache the message for later
    const existing = pendingMessageFromContentScript.get(tabId) || {};
    const propertyName = messageType === 'navType' ? 'type' : 'qualifier';

    pendingMessageFromContentScript.set(tabId, {
      ...existing,
      [propertyName]: messageValue,
      timestamp: Date.now()
    });

    // Auto-cleanup after 500ms
    setTimeout(() => {
      pendingMessageFromContentScript.delete(tabId);
    }, 500);
  }
}

/**
 * Handle messages from content scripts (Safari compatibility)
 */
browser.runtime.onMessage.addListener((message, sender) => {
  const tabId = sender.tab?.id;
  if (!tabId) return;

  if (message.navType) {
    processContentScriptMessage(tabId, 'navType', message.navType, message.url);
  } else if (message.navQualifier) {
    processContentScriptMessage(tabId, 'navQualifier', message.navQualifier, message.url);
  } else if (message.type === 'content_script_loaded') {
    console.log('WikiMapper: Content script loaded confirmation', {
      tabId,
      url: message.url
    });
  }
});

/**
 * Ingest navigation events and filter them by event type.
 * @param {object} details - webNavigation event details
 */
async function eventFilter(details) {
  try {
    console.log('WikiMapper: Navigation event received', {
      url: details.url,
      transitionType: details.transitionType,
      transitionQualifiers: details.transitionQualifiers,
      isSafari,
      hasTransitionSupport
    });

    if (hasTransitionSupport) {
      // Chrome/Firefox: Use native transition info
      if (details.transitionQualifiers?.includes('forward_back')) {
        await Sessions.processForwardBack(details);
      } else if (triggers.includes(details.transitionType)) {
        await Sessions.processNavigation(details);
      }
    } else {
      // Safari: Check if content script message already arrived
      const navInfo = pendingMessageFromContentScript.get(details.tabId);

      if (navInfo) {
        // Message already available, process immediately
        console.log('WikiMapper: Processing navigation with cached content script info', {
          tabId: details.tabId,
          navInfo
        });
        await processNavigationWithInfo(details, navInfo);
        pendingMessageFromContentScript.delete(details.tabId);
      } else {
        // No message yet, cache navigation and wait 500ms
        console.log('WikiMapper: Caching navigation, waiting for content script message', {
          tabId: details.tabId,
          url: details.url
        });

        // Clear any existing timeout for this tab
        const existingPending = pendingMessageFromWebNavigation.get(details.tabId);
        if (existingPending) {
          clearTimeout(existingPending.timeoutId);
        }

        // Set up timeout to process as 'typed' if no message arrives
        const timeoutId = setTimeout(() => {
          consumePendingNavigation(details.tabId, 'typed');
        }, 500);

        pendingMessageFromWebNavigation.set(details.tabId, {
          details,
          timeoutId
        });
      }
    }
  } catch (error) {
    console.error('WikiMapper: Error processing navigation event:', error);
  }
}

// Add navigation listener synchronously
try {
  browser.webNavigation.onCommitted.addListener(eventFilter, {
    url: [
      { urlContains: '.wikipedia.org/' },
      { urlContains: '.wiktionary.org/' }
    ]
  });
  console.log('WikiMapper: webNavigation listener added successfully');
} catch (error) {
  console.error('WikiMapper: Failed to add webNavigation listener:', error);
}

// Clean up caches when tabs are closed (Safari timing coordination)
browser.tabs.onRemoved.addListener((tabId) => {
  if (isSafari) {
    const pendingNav = pendingMessageFromWebNavigation.get(tabId);
    if (pendingNav) {
      clearTimeout(pendingNav.timeoutId);
      pendingMessageFromWebNavigation.delete(tabId);
    }
    pendingMessageFromContentScript.delete(tabId);
    console.log('WikiMapper: Cleaned up caches for closed tab', { tabId });
  }
});

// Listener for when the user clicks on the Wikimapper button
browser.action.onClicked.addListener(() => {
  browser.tabs.create({ url: browser.runtime.getURL('index.html') });
});

// Listener for first install
browser.runtime.onInstalled.addListener((details) => {
  if (details.reason === 'install') {
    browser.tabs.create({ url: 'index.html' });
  }
});

/**
 * Initialize the background script by setting up event listeners.
 * This function is exported for testing purposes.
 */
export async function initialize() {
  try {
    // Detect browser capabilities first
    await detectBrowserCapabilities();

    // Initialize SessionHandler
    await Sessions.initialize();
    console.log('WikiMapper: Initialization complete');
  } catch (error) {
    console.error('WikiMapper: Error during initialization:', error);
    throw error;
  }
}
