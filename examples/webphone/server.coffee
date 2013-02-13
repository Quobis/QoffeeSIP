##
# Copyright (C) Quobis
# Project site: https://github.com/Quobis/QoffeeSIP
# 
# Licensed under GNU-LGPL-3.0-or-later (http://www.gnu.org/licenses/lgpl-3.0.html)
##


#!/usr/bin/env coffee
express = require 'express'


# Se crea la aplicación
app = express()

# Se configura la app
app.configure ->
    # Vistas
    app.set 'views', __dirname + '/views'
    # Utilizar jade en lugar de html
    app.set 'view engine', 'jade'
    # Utilizar el router
    app.use app.router
    # Se sirven estáticamente los archivos de /public
    app.use express.static __dirname + '/public'
    app.use express.favicon 'public/img/favicon/favicon.ico'

# Ruteado
app.get "/", (req, res) ->
    res.render 'index.jade'


# Arrancar servidor
app = app.listen(8080)
