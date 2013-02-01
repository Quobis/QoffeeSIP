build:
	rm -rf dist
	make compile
	mkdir -p dist/simplest-demo
	cp -R lib/ dist/simplest-demo/
	cp ../../dist/qoffeesip/qoffeesip.js dist/simplest-demo/lib
	mv script.js index.html dist/simplest-demo

compile:
	jade index.jade
	coffee -c script.coffee

clean:
	rm -f *.html *.js