#!/usr/bin/python

#############################
# Copyright 2020, Oracle Corporation and/or affiliates.  All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl
# Author: paramdeep.saini@oracle.com
############################

"""
 This file provides the functionality to log the event in console and file
"""

import logging
import os

class LoggingType(object):
   CONSOLE   = 1
   FILE      = 2
   STDOUT    = 3
 
class OraLogger(object):
   """
   This is a class constructor which sets parameter for logger.

   Attributes:
      filename_ (string): Filename which we need to set to store logs in a file.
   """
   def __init__(self, filename_):
      """
        This is a class constructor which sets parameter for logger. 

        Attributes:
           filename_ (string): Filename which we need to set to store logs in a file.
      """
      self.filename_  = filename_
      # Set to default values can be changed later from other classes objects
      self.console_   = LoggingType.CONSOLE
      self.file_      = LoggingType.FILE
      self.stdout_    = LoggingType.STDOUT
      self.msg_       = None  
      self.functname_ = None 
      self.lineno_    = None 
      self.logtype_   = "INFO"
      self.fmtstr_    = "%(asctime)s: %(levelname)s: %(message)s" 
      self.datestr_   = "%m/%d/%Y %I:%M:%S %p"  
      self.root = logging.getLogger()
      self.root.setLevel(logging.DEBUG)
      self.formatter = logging.Formatter('%(asctime)s %(levelname)8s:%(message)s', "%m/%d/%Y %I:%M:%S %p")
      self.stdoutfile_ = "/proc/1/fd/1"
   #   self.stdoutfile_ = "/tmp/test.log"

   def getStdOutValue(self):
      return self.stdout_

class Handler(object):
   """
   This is a class which sets the handler for next logger.
   """
   def __init__(self):
      """
      This is a handler class constructor and nexthandler is set to None.
      """
      self.nextHandler = None

   def handle(self, request):
      '''
      This is a function which set the next handler.

      Attributes:
        request (object): Object of the class oralogger.
      '''
      self.nextHandler.handle(request)

   def print_message(self,request,lhandler):
      """
      This function set the log type to INFO, WARN, DEBUG and CRITICAL.

      Attribute:
         request (object): Object of the class oralogger. 
         lhandler: This parameter accept the loghandler. 
      """
      if request.logtype_ == "WARN":
         request.root.warning(request.msg_) 
      elif request.logtype_ == "DEBUG":
         request.root.debug(request.msg_)         
      elif request.logtype_ == "CRITICAL":
         request.root.critical(request.msg_)
      elif request.logtype_ == "ERROR":
         request.root.error(request.msg_)
      else:
         request.root.info(request.msg_)

      request.root.removeHandler(lhandler)

class FHandler(Handler):
   """
   This is a class which sets the handler for next logger.
   """
   def handle(self,request):
       """
       This function print the message and call next handler.

       Attribut:
          request: Object of OraLogger
       """
       if request.file_ == LoggingType.FILE:
          fh = logging.FileHandler(request.filename_)
          request.root.addHandler(fh)
          fh.setFormatter(request.formatter)
          self.print_message(request,fh)
          super(FHandler, self).handle(request)
       else:
          super(FHandler, self).handle(request)

   def print_message(self,request,fh):
           """
           This function log the message to console/file/stdout.
           """
           super(FHandler, self).print_message(request,fh)
           
class CHandler(Handler):
      """
      This is a class which sets the handler for next logger.
      """
      def handle(self,request):
          """
          This function print the message and call next handler.

          Attribute:
          request: Object of OraLogger
          """
          if request.console_ == LoggingType.CONSOLE:
   #         ch = logging.StreamHandler()
            ch = logging.FileHandler("/tmp/test.log") 
            request.root.addHandler(ch)
            ch.setFormatter(request.formatter)
            self.print_message(request,ch)
            super(CHandler, self).handle(request)
          else:
            super(CHandler, self).handle(request)

      def print_message(self,request,ch):
           """
           This function log the message to console/file/stdout.
           """
           super(CHandler, self).print_message(request,ch)


class StdHandler(Handler):
      """
      This is a class which sets the handler for next logger.
      """
      def handle(self,request):
          """
          This function print the message and call next handler.

          Attribute:
          request: Object of OraLogger
          """
          request.stdout_ =  request.getStdOutValue()
          if request.stdout_ == LoggingType.STDOUT:
            st = logging.FileHandler(request.stdoutfile_)
            request.root.addHandler(st)
            st.setFormatter(request.formatter)
            self.print_message(request,st)
            super(StdHandler, self).handle(request)
          else:
            super(StdHandler, self).handle(request)

      def print_message(self,request,st):
           """
           This function log the message to console/file/stdout.
           """
           super(StdHandler, self).print_message(request,st)

class PassHandler(Handler):
      """
      This is a class which sets the handler for next logger.
      """
      def handle(self, request):
          pass
