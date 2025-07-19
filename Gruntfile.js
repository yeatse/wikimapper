'use strict';

module.exports = function(grunt) {

  // use load-grunt-tasks to read dependencies from package.json
  require('load-grunt-tasks')(grunt);
  require('@lodder/time-grunt')(grunt);

  var config = {
    src: 'src',
    dist: 'dist',
    nodeModules: './node_modules'
  };

  grunt.initConfig({
    config: config,

    clean: {
      dist: {
        files: [{
          dot: true,
          src: [
            '<%= config.dist %>/*',
            '!<%= config.dist %>/.git'
          ]
        }]
      }
    },

    eslint: {
      options: {
        overrideConfigFile: '.eslintrc.json',
        fix: true
      },
      target: [
        '/*.js',
        '<%= config.src %>/**/*.js',
        'test/spec/**/*.js'
      ]
    },

    run: {
      jest: {
        cmd: 'npm',
        args: ['test']
      },
      zip: {
        cmd: './zip_bundles.sh'
      }
    },

    copy: {
      chrome: {
        files: [
          {
            src: './manifest.chrome.json',
            dest: '<%= config.dist %>/chrome/',
            filter: 'isFile',
            flatten: true,
            expand: true,
            rename: function(dest, src) {
              return dest + 'manifest.json';
            }
          },
          {
            src: '<%= config.src %>/web/index.html',
            dest: '<%= config.dist %>/chrome/',
            filter: 'isFile',
            flatten: true,
            expand: true
          },
          {
            src: ['<%= config.src %>/resources/*', '!<%= config.src %>/resources/*.psd'],
            dest: '<%= config.dist %>/chrome/resources',
            filter: 'isFile',
            flatten: true,
            expand: true
          },
          {
            src: '<%= config.nodeModules %>/font-awesome/fonts/*',
            dest: '<%= config.dist %>/chrome/fonts/',
            filter: 'isFile',
            flatten: true,
            expand: true
          }
        ]
      },
      firefox: {
        files: [
          {
            src: './manifest.firefox.json',
            dest: '<%= config.dist %>/firefox/',
            filter: 'isFile',
            flatten: true,
            expand: true,
            rename: function(dest, src) {
              return dest + 'manifest.json';
            }
          },
          {
            src: '<%= config.src %>/web/index.html',
            dest: '<%= config.dist %>/firefox/',
            filter: 'isFile',
            flatten: true,
            expand: true
          },
          {
            src: ['<%= config.src %>/resources/*', '!<%= config.src %>/resources/*.psd'],
            dest: '<%= config.dist %>/firefox/resources',
            filter: 'isFile',
            flatten: true,
            expand: true
          },
          {
            src: '<%= config.nodeModules %>/font-awesome/fonts/*',
            dest: '<%= config.dist %>/firefox/fonts/',
            filter: 'isFile',
            flatten: true,
            expand: true
          }
        ]
      },
      safari: {
        files: [
          {
            src: './manifest.safari.json',
            dest: 'WikiMapper/Shared (Extension)/',
            filter: 'isFile',
            flatten: true,
            expand: true,
            rename: function(dest, src) {
              return dest + 'manifest.json';
            }
          },
          {
            src: '<%= config.src %>/web/index.html',
            dest: 'WikiMapper/Shared (Extension)/',
            filter: 'isFile',
            flatten: true,
            expand: true
          },
          {
            src: ['<%= config.src %>/resources/*', '!<%= config.src %>/resources/*.psd'],
            dest: 'WikiMapper/Shared (Extension)/assets',
            filter: 'isFile',
            flatten: true,
            expand: true
          },
          {
            src: '<%= config.nodeModules %>/font-awesome/fonts/*',
            dest: 'WikiMapper/Shared (Extension)/fonts/',
            filter: 'isFile',
            flatten: true,
            expand: true
          },
          {
            src: '<%= config.src %>/chrome/content-script.js',
            dest: 'WikiMapper/Shared (Extension)/',
            filter: 'isFile',
            flatten: true,
            expand: true
          }
        ]
      }
    },

    less: {
      chrome: {
        options: {
          compress: false,
          sourceMap: true,
          sourceMapFilename: '<%= config.dist %>/chrome/styles/wikimapper.css.map',
          sourceMapURL: 'wikimapper.css.map',
          sourceMapBasepath: '<%= config.dist %>/chrome',
          javascriptEnabled: true
        },
        files: {
          '<%= config.dist %>/chrome/styles/wikimapper.css': '<%= config.src %>/web/styles/*.less'
        }
      },
      firefox: {
        options: {
          compress: false,
          sourceMap: true,
          sourceMapFilename: '<%= config.dist %>/firefox/styles/wikimapper.css.map',
          sourceMapURL: 'wikimapper.css.map',
          sourceMapBasepath: '<%= config.dist %>/firefox',
          javascriptEnabled: true
        },
        files: {
          '<%= config.dist %>/firefox/styles/wikimapper.css': '<%= config.src %>/web/styles/*.less'
        }
      },
      safari: {
        options: {
          compress: false,
          sourceMap: true,
          sourceMapFilename: 'WikiMapper/Shared (Extension)/styles/wikimapper.css.map',
          sourceMapURL: 'wikimapper.css.map',
          sourceMapBasepath: 'WikiMapper/Shared (Extension)',
          javascriptEnabled: true
        },
        files: {
          'WikiMapper/Shared (Extension)/styles/wikimapper.css': '<%= config.src %>/web/styles/*.less'
        }
      }
    },

    webpack: {
      options: {
        stats: !process.env.NODE_ENV || process.env.NODE_ENV === 'development'
      },
      chrome: {
        ...require('./webpack.config.js'),
        mode: 'production',
        output: {
          ...require('./webpack.config.js').output,
          path: require('path').resolve(__dirname, 'dist/chrome')
        }
      },
      firefox: {
        ...require('./webpack.config.js'),
        mode: 'production',
        output: {
          ...require('./webpack.config.js').output,
          path: require('path').resolve(__dirname, 'dist/firefox')
        }
      },
      safari: {
        ...require('./webpack.config.js'),
        mode: 'production',
        plugins: [
          ...require('./webpack.config.js').plugins.filter(plugin => 
            !(plugin instanceof require('webpack').DefinePlugin)
          ),
          new (require('webpack')).DefinePlugin({
            BUILD_TARGET: JSON.stringify('safari')
          })
        ],
        output: {
          ...require('./webpack.config.js').output,
          path: require('path').resolve(__dirname, 'WikiMapper/Shared (Extension)')
        }
      },
      dev: {
        ...require('./webpack.config.js'),
        mode: 'development',
        watch: true,
        output: {
          ...require('./webpack.config.js').output,
          path: require('path').resolve(__dirname, 'dist/chrome')
        }
      }
    }
  });

  // Common preparation steps
  grunt.registerTask('prepare', 'Common preparation steps', [
    'clean:dist',
    'test'
  ]);

  grunt.registerTask('test', 'Run tests', [
    'eslint',
    'run:jest'
  ]);

  // Browser-specific copy tasks
  grunt.registerTask('copy:all', 'Copy files for all browsers', [
    'copy:chrome',
    'copy:firefox',
    'copy:safari'
  ]);

  // Build tasks
  grunt.registerTask('build:chrome', 'Build Chrome extension bundle', [
    'prepare',
    'copy:chrome',
    'less:chrome',
    'webpack:chrome'
  ]);

  grunt.registerTask('build:firefox', 'Build Firefox extension bundle', [
    'prepare',
    'copy:firefox',
    'less:firefox',
    'webpack:firefox'
  ]);

  grunt.registerTask('build:safari', 'Build Safari extension bundle', [
    'prepare',
    'copy:safari',
    'less:safari',
    'webpack:safari'
  ]);

  grunt.registerTask('build:all', 'Build extension bundle for all browsers', [
    'prepare',
    'copy:all',
    'less:chrome',
    'less:firefox',
    'less:safari',
    'webpack:chrome',
    'webpack:firefox',
    'webpack:safari',
    'run:zip'
  ]);

  grunt.registerTask('build:debug', 'Run WikiMapper in debugger/watch mode', [
    'prepare',
    'copy:chrome',
    'less:chrome',
    'webpack:dev'
  ]);
};
