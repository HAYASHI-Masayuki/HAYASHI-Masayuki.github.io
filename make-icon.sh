#!/bin/bash

# https://github.com/Vimux/Mainroad/issues/219#issuecomment-660341662

RGB='rgb(102,204,204)'

convert -size 16x16 xc:black -fill $RGB -draw "rectangle 0,12, 16,16" favicon-16.ico
convert -size 32x32 xc:black -fill $RGB -draw "rectangle 0,24, 32,32" favicon-32.ico
convert -size 48x48 xc:black -fill $RGB -draw "rectangle 0,36, 48,48" favicon-48.ico
convert -size 64x64 xc:black -fill $RGB -draw "rectangle 0,48, 64,64" favicon-64.ico
convert favicon-16.ico favicon-32.ico favicon-48.ico favicon-64.ico static/favicon.ico
rm favicon-{16,32,48,64}.ico

convert -size 180x180 xc:black -fill $RGB -draw "rectangle 0,135, 180,180" static/apple-touch-icon.png
