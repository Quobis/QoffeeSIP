# compile and deploy (useful while developing)
all: watch deploy

# compile automatically each time the user save a file
watch:
	node_modules/coffee-script/bin/coffee -c -b -w public/js/*.coffee  &
	node_modules/stylus/bin/stylus -w public/css/*.styl &
	node_modules/jade/bin/jade -P -w views/*.jade &

# deploy tha app using node.js
deploy:
	cp ../../dist/qoffeesip/qoffeesip.js public/js/lib
	npm start

# clean the environment
clean:
	rm -rf dist/
	rm -f public/js/*.js
	rm -f public/js/lib/qoffeesip.js
	rm -f views/*.html

# compile all modules (used to build)
compile:
	node_modules/coffee-script/bin/coffee -c -b public/js/*.coffee &
	node_modules/stylus/bin/stylus -c public/css/*.styl &
	node_modules/jade/bin/jade -w views/*.jade &

# generate files to distribute the app
build:
	make clean
	make compile
	sleep 1
	mkdir -p dist/webphone/js/lib
	mkdir -p dist/webphone/css
	mkdir -p dist/webphone/img/logos
	mkdir -p dist/webphone/audio
	cp public/js/*.js dist/webphone/js
	cp public/js/lib/*.js dist/webphone/js/lib
	cp ../../dist/qoffeesip/qoffeesip.js dist/webphone/js/lib
	cp public/css/*.css dist/webphone/css
	cp public/img/*.png dist/webphone/img
	cp public/img/logos/logo.png dist/webphone/img/logos/logo.png
	cp public/img/favicon/favicon.ico dist/webphone/
	cp public/audio/* dist/webphone/audio
	node_modules/jade/bin/jade views/index.jade -O dist/webphone