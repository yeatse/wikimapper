/**
 * Collection for interfacing with storage.
 */

import Backbone from 'backbone';
import StorageAdapter from '../../../chrome/safari-storage.js';

const storageAdapter = new StorageAdapter();

export default Backbone.Collection.extend({

  model: Backbone.Model,
  sortingField: 'id',
  sortAscending: false,

  comparator: function(model) {
    // default comparator is id (date) descending
    return -model.get('id');
  },

  /**
   * Custom Fetch
   * Retrieves storage and converts it to a Backbone.Collection
   * @returns {Promise} A promise that resolves when the fetch is complete
   */
  fetch: async function() {
    const self = this;
    try {
      const result = await storageAdapter.get(null);
      const history = [];
      let session = {};
      const keys = Object.keys(result).filter(key => !key.startsWith('safari_'));

      for (let i = 0; i < keys.length; i++) {
        session = {};
        session.id = keys[i];
        session.tree = result[keys[i]];
        history.push(session);
      }

      self.parse(history);
      self.trigger('sync');
      return self;
    } catch (error) {
      console.error('WikiMapper: Failed to fetch storage:', error);
      throw error;
    }
  },

  /**
   * Custom Parse
   * Add chrome.storage.local objects into the collection
   * @param history - chrome.storage.local parsed into an Array of objects
   */
  parse: function(history) {
    history.forEach((session) => {
      session.checked = false;
      session.hidden = false;
      this.add(session);
    });
  },

  /**
   * Return the most recent session model.
   * @returns {Promise<Backbone.Model>} A promise that resolves with the latest session model
   */
  getLatest: function() {
    const self = this;
    return this.fetch().then(function() {
      return self.models.reduce((max, model) =>
        model.id > max.id ? model : max,
      self.models[0]
      );
    });
  },

  /**
   * Set the sorting on the collection by assigning a new comparator function.
   * @param sortBy
   */
  setSortBy: function(sortBy) {
    let direction;

    // if the field is not changing, just toggle the direction
    if (sortBy === this.sortingField) {
      this.sortAscending = !this.sortAscending;
    // otherwise, reset to the default of descending
    } else {
      this.sortAscending = false;
      this.sortingField = sortBy;
    }

    // convert boolean value to pos/neg integer for use in the comparator function
    if (this.sortAscending) {
      direction = 1;
    } else {
      direction = -1;
    }

    // each field needs to be sorted a little differently... ugly
    if (sortBy === 'id') {
      this.comparator = function(model) {
        return direction * model.get('id');
      };
    } else if (sortBy === 'name') {
      this.comparator = function(a, b) {
        // JS/Backbone can't simply sort strings alphabetically in reverse, have to hack it a little bit...
        return direction * a.get('tree').name.localeCompare(b.get('tree').name);
      };
    } else {
      this.comparator = function(model) {
        return direction * model.get('tree')[sortBy];
      };
    }

    this.sort();
  },

  /**
   * Remove selected sessions from the collection and from storage.
   * BEWARE: do not modify the collection during the .each() iteration!!!
   * Doing so breaks the iteration! Instead, remove it from storage and
   * keep a reference to the model in toRemove for bulk removal at the end.
   * @returns {Promise} A promise that resolves when deletion is complete
   */
  deleteChecked: async function() {
    const self = this;
    const toRemove = [];
    const keysToRemove = [];

    self.each(function(session) {
      const sessionId = session.get('id');
      if (session.get('checked')) {
        toRemove.push(session);
        keysToRemove.push(sessionId);
      }
    });

    try {
      if (keysToRemove.length > 0) {
        await storageAdapter.remove(keysToRemove);
      }
      self.remove(toRemove);
      self.trigger('delete');
    } catch (error) {
      console.error('WikiMapper: Failed to delete sessions:', error);
      throw error;
    }
  },

  /**
   * Filter sessions based on search input (case insensitive).
   * Recursively look through the parent node and all its children for the search term.
   * If the search term is not found in any of the session's node names, flag it as hidden.
   * When searching, if a match is found, stop recursing.
   * @param {string} searchTerm
   */
  filterSearch: function(searchTerm) {
    searchTerm = searchTerm.toLowerCase();
    this.searchTerm = searchTerm;

    // recursive children search for search term
    const searchChildren = function(children, searchTerm) {
      if (!children) {
        return false;
      }

      for (let i = 0; i < children.length; i++) {
        const child = children[i];
        const name = child.name.toLowerCase();

        if (name.includes(searchTerm)) {
          return true;
        } else if (child.children) {
          if (searchChildren(child.children, searchTerm)) {
            return true;
          }
        }
      }
    };

    // search through each session in the collection
    this.each(function(session) {
      let containsTerm = false;
      const tree = session.get('tree');
      const name = tree.name.toLowerCase();

      if (name.includes(searchTerm)) {
        containsTerm = true;
      } else {
        containsTerm = searchChildren(tree.children, searchTerm);
      }

      // hide the session if it does not contain the search term
      session.set('hidden', (containsTerm !== true));

      // unselect the session if it is now hidden, lest we inadvertently delete it
      if (session.get('checked') && !containsTerm) {
        session.set('checked', false);
      }
    });

    // we're done searching, trigger the filter event to re-render the view
    this.trigger('filter');
  }
});
