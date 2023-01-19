//
//  HTML.swift
//  IETFNext
//
//  Created by Tom Pusateri on 12/14/22.
//

import Foundation

let BLANK = """
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <title>Blank</title>
    <style type="text/css" media="screen">
      :root {
          color-scheme: light dark;
      }
    </style>
  </head>
  <body>
    <div></div>
  </body>
</html>
"""

let PLAIN_PRE = """
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <title></title>
    <style type="text/css" media="screen">
      :root {
          color-scheme: light dark;
      }
      a:link {
          color: #3A82F6;
      }
      a.visited {
          color: #3A82F6;
      }
      pre {
         font-family: monospace;
         white-space: pre-wrap;
      }
    </style>
  </head>
  <body>
    <pre>
"""

let PLAIN_POST = """
    </pre>
  </body>
</html>
"""

let IMAGE_PRE = """
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <style type="text/css" media="screen">
      :root {
          color-scheme: light dark;
      }
      img {
      width: 90%;
      display: block;
      margin-left: auto;
      margin-right: auto;
      margin-top: 40px;
      }
    </style>
  </head>
  <body>
    <div>
        <img src="
"""

let IMAGE_POST = """
">
    </div>
  </body>
</html>
"""

let MD_PRE = """
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <title></title>
    <style type="text/css" media="screen">
      :root {
          color-scheme: light dark;
      }
      body {
          font-family: -apple-system, "courier new", courier, monospace;
      }
      a:link {
          color: #3A82F6;
      }
      a.visited {
          color: #3A82F6;
      }
    </style>
  </head>
  <body>
"""

let MD_POST = """
  </body>
</html>
"""

let HTML_INSERT_STYLE = """
<style type="text/css" media="screen">
    :root {
        color-scheme: light dark;
    }
    body {
        font-family: -apple-system, "courier new", courier, monospace;
    }
    a:link {
        color: #3A82F6;
    }
    a.visited {
        color: #3A82F6;
    }
</style>
"""

let SVG_PRE = """
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <style type="text/css" media="screen">
      :root {
          color-scheme: light dark;
      }
      a:link {
          color: #3A82F6;
      }
      a:visited {
          color: purple;
      }
      @media (prefers-color-scheme: light) {
        body { background-color: white; }
      }
      @media (prefers-color-scheme: dark) {
        body { background-color: black; }
      }
      svg { margin-left:auto; margin-right:auto; display:block; }
    </style>
  </head>
  <body>
    <div>
"""

let SVG_POST = """
    </div>
  </body>
</html>
"""
