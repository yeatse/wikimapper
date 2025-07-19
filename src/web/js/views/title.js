/**
 * Index/Title View
 */

// External Dependencies
import Backbone from 'backbone';

// Internal Dependencies
import enums from '../enums';
import templates from '../templates';
import ViewState from '../models/view-state';

export default Backbone.View.extend({

  template: templates.get('title'),

  initialize: function() {
    ViewState.setNavState('title', enums.nav.active);
  },

  render: function() {
    const iconPath = typeof BUILD_TARGET !== 'undefined' && BUILD_TARGET === 'safari'
      ? 'assets/'
      : 'resources/';

    this.$el.html(this.template({
      iconPath
    }));
  }

});
