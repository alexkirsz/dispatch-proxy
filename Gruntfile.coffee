module.exports = (grunt) ->
  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'

    watch:
      src:
        files: 'src/**/*.coffee'
        tasks: ['default']
        options:
          spawn: false

    coffee:
      compile:
        expand: true
        cwd: 'src/'
        src: '**/*.coffee'
        dest: 'lib/'
        ext: '.js'
        options:
          bare: true

    clean: ['lib/']

  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-clean'

  grunt.registerTask 'default', ['clean', 'coffee:compile']
  grunt.registerTask 'demon', ['default', 'watch:src']
