#!/bin/sh

# start php-fpm service and don't run this again

/usr/bin/php-fpm

sv down php-fpm
