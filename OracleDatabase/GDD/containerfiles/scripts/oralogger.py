#!/usr/bin/python
# LICENSE UPL 1.0
#
# Copyright (c) 2020,2021 Oracle and/or its affiliates.
#
# Since: January, 2020
# Author: sanjay.singh@oracle.com, paramdeep.saini@oracle.com

"""
This file provides the functionality to log events to stdout and file.
"""

import logging
import logging.handlers
import os
import sys
import time


class SizeBasedTimestampRotatingFileHandler(logging.handlers.RotatingFileHandler):
   """
   Rotate on file size and timestamp only rotated files.

   Active file always remains at `baseFilename`.
   Rotated file naming format: `<baseFilename>.YYYYmmddHHMMSS`
   """

   def __init__(self, filename, max_bytes, backup_count=0):
      super(SizeBasedTimestampRotatingFileHandler, self).__init__(
         filename,
         mode="a",
         maxBytes=max_bytes,
         backupCount=backup_count
      )

   def _cleanup_old_backups(self):
      if self.backupCount <= 0:
         return

      base = os.path.basename(self.baseFilename)
      folder = os.path.dirname(self.baseFilename) or "."
      prefix = base + "."
      try:
         backups = []
         for name in os.listdir(folder):
            if name.startswith(prefix):
               full_path = os.path.join(folder, name)
               if os.path.isfile(full_path):
                  backups.append(full_path)
         backups.sort(key=lambda p: os.path.getmtime(p), reverse=True)
         for old_file in backups[self.backupCount:]:
            try:
               os.remove(old_file)
            except OSError:
               pass
      except OSError:
         pass

   def doRollover(self):
      if self.stream:
         self.stream.close()
         self.stream = None

      timestamp = time.strftime("%Y%m%d%H%M%S", time.gmtime())
      rotated_file = self.baseFilename + "." + timestamp
      counter = 1
      while os.path.exists(rotated_file):
         rotated_file = self.baseFilename + "." + timestamp + "." + str(counter)
         counter += 1

      if os.path.exists(self.baseFilename):
         os.rename(self.baseFilename, rotated_file)

      self._cleanup_old_backups()
      if not self.delay:
         self.stream = self._open()


class LoggingType(object):
   CONSOLE = 1
   FILE = 2
   STDOUT = 3


class OraLogger(object):
   """
   Logger request object carried through the existing handler chain.

   Attributes:
      filename_ (string): File path used by `FHandler`.
   """

   def __init__(self, filename_):
      self.filename_ = filename_
      # Existing flags consumed by handlers and callers.
      self.console_ = LoggingType.CONSOLE
      self.file_ = LoggingType.FILE
      self.stdout_ = LoggingType.STDOUT
      self.msg_ = None
      self.functname_ = None
      self.lineno_ = None
      self.logtype_ = "INFO"
      self.fmtstr_ = "%(asctime)s %(levelname)8s:%(message)s"
      self.datestr_ = "%m/%d/%Y %I:%M:%S %p"
      # Use per-instance logger to avoid global root side effects.
      self.root = logging.getLogger("orasharding.%s" % id(self))
      self.root.setLevel(logging.DEBUG)
      self.root.propagate = False
      self.formatter = logging.Formatter(self.fmtstr_, self.datestr_)
      # Preserve current environment-based behavior.
      if os.environ.get("CRS_GPC") == "true" or os.environ.get("CRS_RACDB") == "true":
         base_tmp = (
            os.environ.get("TMP_DIR")
            or os.environ.get("LOG_DIR")
            or os.environ.get("SHARDING_LOG_DIR")
            or os.environ.get("TMPDIR")
            or "."
         )
         self.stdoutfile_ = os.path.join(base_tmp, "test_shard.log")
      else:
         self.stdoutfile_ = "/proc/1/fd/1"
      self._level_handlers_ = {
         "WARN": self.root.warning,
         "WARNING": self.root.warning,
         "DEBUG": self.root.debug,
         "CRITICAL": self.root.critical,
         "ERROR": self.root.error,
         "INFO": self.root.info,
      }
      # Rotate log files by size (10MB) by default.
      self.log_rotate_bytes_ = int(os.environ.get("ORA_LOG_ROTATE_BYTES", str(10* 1024 * 1024)))
      self.log_rotate_backup_count_ = int(os.environ.get("ORA_LOG_ROTATE_BACKUPS", "24"))
      self.console_log_level_ = self._normalize_console_level(
         os.environ.get("CONSOLE_LOG_LEVEL", "ERROR")
      )
      self.force_console_ = False
      self._level_rank_ = {
         "DEBUG": 10,
         "INFO": 20,
         "WARN": 30,
         "WARNING": 30,
         "ERROR": 40,
         "CRITICAL": 50,
      }

   def _normalize_console_level(self, raw_level):
      level = str(raw_level or "").strip().upper()
      if level == "WARNING":
         level = "WARN"
      if level in ("DEBUG", "INFO", "WARN", "ERROR", "CRITICAL"):
         return level
      return "ERROR"

   def should_emit_to_console(self):
      if self.force_console_:
         return True
      msg_level = str(self.logtype_ or "INFO").upper()
      if msg_level == "WARNING":
         msg_level = "WARN"
      msg_rank = self._level_rank_.get(msg_level, 20)
      threshold_rank = self._level_rank_.get(self.console_log_level_, 40)
      return msg_rank >= threshold_rank

   def getStdOutValue(self):
      return self.stdout_

   def getFileRotationBytes(self):
      return self.log_rotate_bytes_

   def getFileRotationBackupCount(self):
      return self.log_rotate_backup_count_

   def buildRotatingFileHandler(self, file_path):
      """
      Build a size-based rotating handler for file logging.
      """
      return SizeBasedTimestampRotatingFileHandler(
         file_path,
         max_bytes=self.getFileRotationBytes(),
         backup_count=self.getFileRotationBackupCount()
      )


class Handler(object):
   """
   Base chain-of-responsibility handler.
   """

   def __init__(self):
      self.nextHandler = None

   def handle(self, request):
      if self.nextHandler is not None:
         self.nextHandler.handle(request)

   def _emit(self, request):
      message = request.msg_
      if message is None:
         message = ""
      level = str(request.logtype_ or "INFO").upper()
      log_fn = request._level_handlers_.get(level, request.root.info)
      log_fn(message)

   def _ensure_dir(self, path):
      directory = os.path.dirname(path)
      if directory and not os.path.exists(directory):
         os.makedirs(directory)

   def _attach_and_log(self, request, handler):
      request.root.addHandler(handler)
      handler.setFormatter(request.formatter)
      self.print_message(request, handler)

   def print_message(self, request, lhandler):
      try:
         self._emit(request)
      finally:
         request.root.removeHandler(lhandler)
         try:
            lhandler.close()
         except Exception:
            pass


class FHandler(Handler):
   """
   File log handler based on `request.filename_`.
   """

   def handle(self, request):
      if request.file_ == LoggingType.FILE and request.filename_:
         # Only proceed if filename is not the stdout sentinel and not empty
         if request.filename_ != "/proc/1/fd/1":
            self._ensure_dir(request.filename_)
            fh = request.buildRotatingFileHandler(request.filename_)
            self._attach_and_log(request, fh)
      super(FHandler, self).handle(request)

   def print_message(self, request, fh):
      super(FHandler, self).print_message(request, fh)


class CHandler(Handler):
   """
   Console log handler (stdout stream).
   If StdHandler is configured to also use stdout ("/proc/1/fd/1"), skip here to avoid duplicate stdout writes.
   """

   def handle(self, request):
      will_stdhandler_use_stdout = (
            getattr(request, "stdout_", None) == LoggingType.STDOUT
            and getattr(request, "stdoutfile_", None) == "/proc/1/fd/1"
            and request.should_emit_to_console()
        )
      if request.console_ == LoggingType.CONSOLE and not will_stdhandler_use_stdout and request.should_emit_to_console():
         ch = logging.StreamHandler(sys.stdout)
         self._attach_and_log(request, ch)
      super(CHandler, self).handle(request)

   def print_message(self, request, ch):
      super(CHandler, self).print_message(request, ch)


class StdHandler(Handler):
   """
   Stdout handler preserving existing stdoutfile_ behavior.
   """

   def handle(self, request):
      request.stdout_ = request.getStdOutValue()
      if request.stdout_ == LoggingType.STDOUT:
         if request.stdoutfile_ == "/proc/1/fd/1":
            if not request.should_emit_to_console():
               super(StdHandler, self).handle(request)
               return
            st = logging.StreamHandler(sys.stdout)
         else:
            self._ensure_dir(request.stdoutfile_)
            st = request.buildRotatingFileHandler(request.stdoutfile_)
         self._attach_and_log(request, st)
      super(StdHandler, self).handle(request)

   def print_message(self, request, st):
      super(StdHandler, self).print_message(request, st)


class PassHandler(Handler):
   """
   Terminal no-op handler.
   """

   def handle(self, request):
      return
