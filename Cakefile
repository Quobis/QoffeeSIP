{exec}  = require "child_process"
fs      = require "fs"

# Paths to npm downloaded binaries
doccob  = "node_modules/docco/bin/docco"
coffeeb = "node_modules/coffee-script/bin/coffee"


# Clean the environment
task "clean", "Clean the environment.", ->
	exec "rm -rf docs/; rm -f src/*.js", (err, stdout, stderr) ->
		throw err if err
		console.log stdout + stderr
		console.log "docs/ folder was deleted."

# Generate Docco documentation
task "doc", "Generate Docco documentation.", ->
	exec "#{doccob} src/*.coffee", (err, stdout, stderr) ->
		throw err if err
		console.log stdout + stderr
		console.log "Documentation generated in doc/ folder."


# Build the stack
# File which are going to be compiled
appFiles = [
	"external/RTC/adapter.coffee"
	"external/RTC/rtc.coffee"
	"src/parser.coffee"
	"src/siptransaction.coffee"
	"src/sipstack.coffee"
	"src/QS.coffee"
]

task "build", "Build the stack from source files", ->
	# delete old stuff
	exec "rm -rf dist", (err, stdout, stderr) ->
		throw err if err
		
		# join all .coffee files
		appContents = new Array remaining = appFiles.length
		for file, index in appFiles then do (file, index) ->
			fs.readFile "#{file}", "utf8", (err, fileContents) ->
				throw err if err
				appContents[index] = fileContents
				process() if --remaining is 0
		process = ->
			fs.mkdirSync "dist"
			fs.writeFile "dist/qoffeesip.coffee", appContents.join("\n\n"), "utf8", (err) ->
				throw err if err
				# and compile it
				exec "#{coffeeb} -c dist/qoffeesip.coffee", (err, stdout, stderr) ->
					throw err if err
					fs.unlink "dist/qoffeesip.coffee", (err) ->
						throw err if err
						# add license advertisement
						exec "cat LICENSE-min > tmp.js; cat dist/qoffeesip.js >> tmp.js; mv tmp.js dist/qoffeesip.js", (err, stdout, stderr) ->
							throw err if err
							# console.log stdout + stderr
							console.log "All sources were compiled to dist/qoffeesip.js."


# Build a minimizied copy of the stack
task "minify", "Build a minimizied copy of the stack.", ->
	exec 'java -jar "external/compiler.jar" --js dist/qoffeesip.js --js_output_file dist/qoffeesip-min.js', (err, stdout, stderr) ->
		throw err if err
		# add license
		exec "cat LICENSE-min > tmp.js; cat dist/qoffeesip-min.js >> tmp.js; mv tmp.js dist/qoffeesip-min.js", (err, stdout, stderr) ->
			throw err if err
			console.log stdout + stderr
			console.log "A minimized copy of QoffeeSIP has been built in dist/qoffeesip-min.js."
