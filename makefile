# generate files to distribute the stack
build: 
	rm -rf dist
	make compile
	# destination folder
	mkdir -p dist/qoffeesip
	# concatenate all .js files
	cat src/lib/md5.js src/rtc.js src/parser.js src/siptransaction.js src/sipstack.js src/API.js > tmp.js
	# ensure that .js ends with ; to avoid wrong concatenation
	echo ";" >> tmp.js
	node_modules/uglify-js/bin/uglifyjs tmp.js > tmp.min.js
	# add license to minified code and tag with the source of the stack
	# to respect FSF recommendations
	cat LICENSE-min tmp.js > dist/qoffeesip/qoffeesip.js
	cat LICENSE-min tmp.min.js > dist/qoffeesip/qoffeesip.min.js
	rm -f tmp*.js
	
# clean the environment
clean:
	rm -rf docs
	rm -f src/*.js

# documentation generation
doc:
	make clean
	node_modules/docco/bin/docco src/*.coffee

# compile all modules (used to build)
compile:
	node_modules/coffee-script/bin/coffee -b -c -l src/*.coffee