#!/usr/bin/python

#############################
# Copyright 2020-2025, Oracle Corporation and/or affiliates.  All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl
# Author: paramdeep.saini@oracle.com
############################

"""
This file provides the functionality to log events on stdout and file.
It keeps backward-compatible handler classes used by existing scripts.
"""

import logging
import os
import re
import sys
import threading
import time
from logging.handlers import RotatingFileHandler
import gzip
import shutil


class LoggingType(object):
   CONSOLE = 1
   FILE = 2
   STDOUT = 3


class SizeTimestampRotatingHandler(RotatingFileHandler):
   """
   Rotate by size, keep active file name stable, and compress rotated files
   only after they have aged past 24 hours.
   """

   def __init__(self, filename, max_bytes, backup_count=None, backupCount=None):
      # Accept both snake_case and stdlib-style backupCount for compatibility.
      if backup_count is None:
         backup_count = backupCount if backupCount is not None else 0
      super(SizeTimestampRotatingHandler, self).__init__(
         filename,
         mode="a",
         maxBytes=max_bytes,
         backupCount=backup_count,
         encoding="utf-8",
      )
      base = os.path.basename(self.baseFilename)
      self._rotated_name_re = re.compile(r"^{0}\.[0-9]{{14}}(?:\.[0-9]+)?$".format(re.escape(base)))
      self._compress_interval_secs = 24 * 60 * 60
      self._rollover_interval_secs = 24 * 60 * 60

   def _should_time_rollover(self):
      if not os.path.exists(self.baseFilename):
         return False
      try:
         last_modified = os.path.getmtime(self.baseFilename)
      except OSError:
         return False
      return (time.time() - last_modified) >= self._rollover_interval_secs

   def _next_timestamp_name(self):
      ts = time.strftime("%Y%m%d%H%M%S", time.gmtime())
      candidate = "{0}.{1}".format(self.baseFilename, ts)
      idx = 1
      while os.path.exists(candidate) or os.path.exists(candidate + ".gz"):
         candidate = "{0}.{1}.{2}".format(self.baseFilename, ts, idx)
         idx += 1
      return candidate

   def _compress_rotated_files_if_due(self):
      folder = os.path.dirname(self.baseFilename) or "."
      base = os.path.basename(self.baseFilename)
      try:
         for name in os.listdir(folder):
            if not self._rotated_name_re.match(name):
               continue
            src = os.path.join(folder, name)
            dst = src + ".gz"
            if not os.path.isfile(src):
               continue
            try:
               if (time.time() - os.path.getmtime(src)) < self._compress_interval_secs:
                  continue
            except OSError:
               continue
            with open(src, "rb") as src_fp, gzip.open(dst, "wb") as dst_fp:
               shutil.copyfileobj(src_fp, dst_fp)
            os.remove(src)
      except Exception:
         # Keep logging non-blocking even if compression fails.
         pass

      self._enforce_backup_count(base, folder)

   def _enforce_backup_count(self, base, folder):
      if self.backupCount <= 0:
         return
      prefix = base + "."
      rotated = []
      try:
         for name in os.listdir(folder):
            if not name.startswith(prefix):
               continue
            full = os.path.join(folder, name)
            if os.path.isfile(full):
               rotated.append(full)
      except Exception:
         return
      rotated.sort(key=lambda p: os.path.getmtime(p), reverse=True)
      for stale in rotated[self.backupCount:]:
         try:
            os.remove(stale)
         except Exception:
            pass

   def emit(self, record):
      self._compress_rotated_files_if_due()
      if self._should_time_rollover():
         self.doRollover()
      super(SizeTimestampRotatingHandler, self).emit(record)

   def doRollover(self):
      if self.stream:
         self.stream.close()
         self.stream = None

      if os.path.exists(self.baseFilename):
         os.rename(self.baseFilename, self._next_timestamp_name())

      if not self.delay:
         self.stream = self._open()


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
      self.filename_ = filename_
      # Set to default values can be changed later from other classes objects
      self.console_ = LoggingType.CONSOLE
      self.file_ = LoggingType.FILE
      self.stdout_ = LoggingType.STDOUT
      self.msg_ = None
      self.functname_ = None
      self.lineno_ = None
      self.logtype_ = "INFO"
      self.fmtstr_ = "%(asctime)s: %(levelname)s: %(message)s"
      self.datestr_ = "%m/%d/%Y %I:%M:%S %p"
      self.root = logging.getLogger("orac.rac.{0}".format(id(self)))
      self.root.setLevel(logging.DEBUG)
      self.root.propagate = False
      self.formatter = logging.Formatter('%(asctime)s %(levelname)8s:%(message)s', "%m/%d/%Y %I:%M:%S %p")
      self.stdoutfile_ = "/proc/1/fd/1"
      self._lock = threading.RLock()
      self._configured_filename = None
      self._stdout_enabled = True
      self._rotate_max_bytes = int(os.environ.get("ORA_LOG_MAX_BYTES", str(100 * 1024)))
      self._archive_backup_count = int(os.environ.get("ORA_LOG_BACKUP_COUNT", "14"))
      self._configure_logger(self.filename_)

   def getStdOutValue(self):
      return self.stdout_

   def _resolve_archive_dir(self, logfile):
      archive_dir = os.environ.get("ORA_LOG_ARCHIVE_DIR")
      if archive_dir:
         return archive_dir
      basedir = os.path.dirname(logfile) or "."
      return os.path.join(basedir, "archive")

   def _configure_logger(self, logfile):
      with self._lock:
         logfile = logfile or "/tmp/orod/oracle_db_setup.log"
         logdir = os.path.dirname(logfile) or "."
         os.makedirs(logdir, exist_ok=True)

         for handler in list(self.root.handlers):
            self.root.removeHandler(handler)
            try:
               handler.close()
            except Exception:
               pass

         if self._stdout_enabled:
            stream_handler = logging.StreamHandler(sys.stdout)
            stream_handler.setFormatter(self.formatter)
            self.root.addHandler(stream_handler)

         file_handler = SizeTimestampRotatingHandler(
            logfile,
            max_bytes=self._rotate_max_bytes,
            backupCount=self._archive_backup_count,
         )
         file_handler.setFormatter(self.formatter)
         self.root.addHandler(file_handler)
         self._configured_filename = logfile

   def emit(self, message, logtype=None):
      with self._lock:
         if self._configured_filename != self.filename_:
            self._configure_logger(self.filename_)

         level = (logtype or self.logtype_ or "INFO").upper()
         if level == "WARN":
            level = "WARNING"

         msg = "" if message is None else str(message)
         if level == "DEBUG":
            self.root.debug(msg)
         elif level == "CRITICAL":
            self.root.critical(msg)
         elif level == "ERROR":
            self.root.error(msg)
         elif level == "WARNING":
            self.root.warning(msg)
         else:
            self.root.info(msg)

   def force_rotate(self):
      with self._lock:
         if self._configured_filename != self.filename_:
            self._configure_logger(self.filename_)
         for handler in self.root.handlers:
            if isinstance(handler, SizeTimestampRotatingHandler):
               handler.doRollover()

   def set_stdout_enabled(self, enabled):
      with self._lock:
         self._stdout_enabled = bool(enabled)
         self._configure_logger(self.filename_)

   def close(self):
      with self._lock:
         for handler in list(self.root.handlers):
            self.root.removeHandler(handler)
            try:
               handler.close()
            except Exception:
               pass


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
      """
      This is a function which set the next handler.

      Attributes:
        request (object): Object of the class oralogger.
      """
      if self.nextHandler is not None:
         self.nextHandler.handle(request)

   def print_message(self, request, lhandler):
      """
      This function set the log type to INFO, WARN, DEBUG and CRITICAL.

      Attribute:
         request (object): Object of the class oralogger.
         lhandler: This parameter accept the loghandler.
      """
      request.emit(request.msg_, request.logtype_)


class FHandler(Handler):
   """
   This is a class which sets the handler for next logger.
   """

   def handle(self, request):
      """
      This function print the message and call next handler.

      Attribut:
         request: Object of OraLogger
      """
      super(FHandler, self).handle(request)

   def print_message(self, request, fh):
      """
      This function log the message to console/file/stdout.
      """
      super(FHandler, self).print_message(request, fh)


class CHandler(Handler):
   """
   This is a class which sets the handler for next logger.
   """

   def handle(self, request):
      """
      This function print the message and call next handler.

      Attribute:
      request: Object of OraLogger
      """
      super(CHandler, self).handle(request)

   def print_message(self, request, ch):
      """
      This function log the message to console/file/stdout.
      """
      super(CHandler, self).print_message(request, ch)


class StdHandler(Handler):
   """
   This is a class which sets the handler for next logger.
   """

   def handle(self, request):
      """
      This function print the message and call next handler.

      Attribute:
      request: Object of OraLogger
      """
      request.stdout_ = request.getStdOutValue()
      if request.stdout_ == LoggingType.STDOUT:
         self.print_message(request, None)
      else:
         super(StdHandler, self).handle(request)

   def print_message(self, request, st):
      """
      This function log the message to console/file/stdout.
      """
      super(StdHandler, self).print_message(request, st)


class PassHandler(Handler):
   """
   This is a class which sets the handler for next logger.
   """

   def handle(self, request):
      pass
