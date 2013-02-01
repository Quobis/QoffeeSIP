build:
	make clean
	make compile
	mkdir -p dist/sipwebsockets-scanner/
	cp -R lib/ dist/sipwebsockets-scanner/
	cp ../../dist/qoffeesip/qoffeesip.js dist/sipwebsockets-scanner/lib
	mv script.js index.html dist/sipwebsockets-scanner/
	
compile:
	jade index.jade
	coffee -c script.coffee

clean:
	rm -rf dist
	rm -f *.html *.js
