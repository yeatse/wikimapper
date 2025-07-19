/**
 * Safari native storage adapter using SafariWebExtensionHandler
 */

class SafariStorage {
  constructor() {
    this.isAvailable = typeof browser !== 'undefined' &&
                       typeof browser.runtime !== 'undefined' &&
                       typeof browser.runtime.sendNativeMessage !== 'undefined';
  }

  /**
   * Send message to native Safari extension handler
   * @param {object} message - Message to send
   * @returns {Promise<object>} Response from native handler
   */
  async sendMessage(message) {
    if (!this.isAvailable) {
      throw new Error('Safari native messaging not available');
    }

    try {
      const response = await browser.runtime.sendNativeMessage('application.wikimapper', message);
      if (response.error) {
        throw new Error(response.error);
      }
      return response;
    } catch (error) {
      console.error('WikiMapper: Safari native message failed:', error);
      throw error;
    }
  }

  /**
   * Set data in native storage
   * @param {object} data - Key-value pairs to store
   * @returns {Promise<void>}
   */
  async set(data) {
    const response = await this.sendMessage({
      action: 'set',
      data
    });
    return response.success;
  }

  /**
   * Get data from native storage
   * @param {string|string[]|null} keys - Keys to retrieve, or null for all
   * @returns {Promise<object>} Retrieved data
   */
  async get(keys) {
    let keysArray = null;
    if (typeof keys === 'string') {
      keysArray = [keys];
    } else if (Array.isArray(keys)) {
      keysArray = keys;
    }

    const response = await this.sendMessage({
      action: 'get',
      keys: keysArray
    });
    const result = response.result || {};
    return JSON.parse(JSON.stringify(result));
  }

  /**
   * Remove data from native storage
   * @param {string|string[]} keys - Keys to remove
   * @returns {Promise<void>}
   */
  async remove(keys) {
    const keysArray = Array.isArray(keys) ? keys : [keys];
    const response = await this.sendMessage({
      action: 'remove',
      keys: keysArray
    });
    return response.success;
  }

  /**
   * Clear all data from native storage
   * @returns {Promise<void>}
   */
  async clear() {
    const response = await this.sendMessage({
      action: 'clear'
    });
    return response.success;
  }

  /**
   * Get bytes in use
   * @returns {Promise<number>} Bytes used
   */
  async getBytesInUse() {
    const response = await this.sendMessage({
      action: 'getBytesInUse'
    });
    return response.bytesInUse || 0;
  }
}

/**
 * Storage adapter that uses Safari native storage when available,
 * falls back to chrome.storage.local otherwise
 */
class StorageAdapter {
  constructor() {
    this.safariStorage = new SafariStorage();
    this.useSafariStorage = this.safariStorage.isAvailable;
    console.log('WikiMapper: Storage adapter initialized', {
      useSafariStorage: this.useSafariStorage
    });
  }

  /**
   * Set data in storage
   * @param {object} data - Key-value pairs to store
   * @returns {Promise<void>}
   */
  async set(data) {
    if (this.useSafariStorage) {
      return await this.safariStorage.set(data);
    } else {
      return new Promise((resolve) => {
        chrome.storage.local.set(data, resolve);
      });
    }
  }

  /**
   * Get data from storage
   * @param {string|string[]|object|null} keys - Keys to retrieve
   * @returns {Promise<object>} Retrieved data
   */
  async get(keys) {
    if (this.useSafariStorage) {
      return await this.safariStorage.get(keys);
    } else {
      return new Promise((resolve) => {
        chrome.storage.local.get(keys, resolve);
      });
    }
  }

  /**
   * Remove data from storage
   * @param {string|string[]} keys - Keys to remove
   * @returns {Promise<void>}
   */
  async remove(keys) {
    if (this.useSafariStorage) {
      return await this.safariStorage.remove(keys);
    } else {
      return new Promise((resolve) => {
        chrome.storage.local.remove(keys, resolve);
      });
    }
  }

  /**
   * Clear all data from storage
   * @returns {Promise<void>}
   */
  async clear() {
    if (this.useSafariStorage) {
      return await this.safariStorage.clear();
    } else {
      return new Promise((resolve) => {
        chrome.storage.local.clear(resolve);
      });
    }
  }

  /**
   * Get bytes in use
   * @returns {Promise<number>} Bytes used
   */
  async getBytesInUse() {
    if (this.useSafariStorage) {
      return await this.safariStorage.getBytesInUse();
    } else {
      return new Promise((resolve) => {
        chrome.storage.local.getBytesInUse(null, resolve);
      });
    }
  }
}

export default StorageAdapter;
