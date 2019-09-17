// Copyright 2019, Oracle Corporation and/or its affiliates.  All rights reserved.
// Licensed under the Universal Permissive License v 1.0 as shown at
// http://oss.oracle.com/licenses/upl.

package cohapp;

import com.tangosol.net.CacheFactory;
import com.tangosol.net.ConfigurableCacheFactory;
import com.tangosol.net.NamedCache;
import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.net.URISyntaxException;
import java.net.URL;
import java.nio.file.FileSystems;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * MBean unit test class. This test creates a coherence cluster so we may want to move it into a
 * functional test.
 */
public class CacheClient {

  private static final String PREFIX = "Thread-";
  private static final int VALUE_SIZE = 1024;
  private static final int NUM_ITEMS = 10 * 1000;  // Total number of items, regardless of thread count
  private static final int THREAD_COUNT = 1;
  private static final int MAX_BATCH_SIZE = 1000;

  // For HA testing, delay between operations until we do failover then go fast.
  private static volatile int delay = 0;

  // Debug
  static AtomicInteger mapWriteCount = new AtomicInteger();


  private Path opConfigPath = null;
  private Path clientCacheConfigPath = null;

  private final String KEY = "testKey";
  private final String VAL = "testVal";

  private final String CACHE_NAME = "test-cache-remote";

  private static final String SUCCESS = "Success";
  private static final String FAILURE = "Failure";

  public void loadCache() {
    try {
      init();
      loadCacheInternal();
    } finally {
      cleanup();
    }
  }

  public void validateCache() {
    try {
      init();
      validateCacheInternal();
    } finally {
      cleanup();
    }
  }

  private void init() {
    try {
      // create a temp file to write cache config - this is needed to run jar from cmd line
      Path path = FileSystems.getDefault().getPath("tmp-client-cache-config.xml");
      clientCacheConfigPath = path.toAbsolutePath();
      Files.deleteIfExists(clientCacheConfigPath);
      PrintWriter writer = new PrintWriter( new FileWriter(new File(clientCacheConfigPath.toString())));

      // get reader of cache config inside the jar
      BufferedReader reader = new BufferedReader(new InputStreamReader(
          this.getClass().getResourceAsStream("/client-cache-config.xml")));

      String line;
      while ((line = reader.readLine()) != null) {
        writer.println(line);
      }
      writer.close();

    } catch (Exception e) {
      throw new IllegalStateException("Error accessing the client cache config file ", e);
    }

    // This will prevent client from joining the cluster
    System.setProperty("coherence.tcmp.enabled","fase");
  }

  private void cleanup() {
    try {
      Files.deleteIfExists(clientCacheConfigPath);
    } catch (Exception e) {}
  }

  private static String getStackTraceString(Exception e) {
    StringWriter writer = new StringWriter();
    e.printStackTrace(new PrintWriter(writer));
    return writer.toString();
  }

  private void loadCacheInternal() {

    List<CacheThread> threadList = new ArrayList<>();

    // Clear the cache
    NamedCache cache = getCcf().ensureCache(CACHE_NAME, this.getClass().getClassLoader());

    cache = getCcf().ensureCache(CACHE_NAME, this.getClass().getClassLoader());
    System.out.println("Cache size = " + cache.size());

    System.out.println("Clearing cache");
    cache.clear();

   // System.exit(0);

    System.out.println("Loading cache");
    Instant startInstant = Instant.now();
    // Load the cache
    for (int i = 0; i < THREAD_COUNT; i++) {
      CacheThread t =
          new WriteThread(
              new ThreadConfig(
                  this.getClass().getClassLoader(),
                  "Write",
                  getCcf(),
                  CACHE_NAME,
                  PREFIX + i,
                  NUM_ITEMS/THREAD_COUNT));
      t.setDaemon(true);
      t.start();
      threadList.add(t);
    }
    waitForAllThread(threadList);


    cache = getCcf().ensureCache(CACHE_NAME, this.getClass().getClassLoader());
    System.out.println("Cache size = " + cache.size());

    Instant finishInstant = Instant.now();
    Duration duration = Duration.between(startInstant, finishInstant);

    System.out.println("SUCCESS Load Test - elapsed Time = " + duration.getSeconds() + " seconds");
  }

  private void validateCacheInternal() {

    List<CacheThread> threadList = new ArrayList<>();

    Instant startInstant = Instant.now();

    NamedCache cache = getCcf().ensureCache(CACHE_NAME, this.getClass().getClassLoader());

    cache = getCcf().ensureCache(CACHE_NAME, this.getClass().getClassLoader());
    System.out.println("Cache size = " + cache.size());

    // Verify the cache
    threadList.clear();
    for (int i = 0; i < THREAD_COUNT; i++) {
      CacheThread t =
          new ValidateThread(
              new ThreadConfig(
                  this.getClass().getClassLoader(),
                  "Validate",
                  getCcf(),
                  CACHE_NAME,
                  PREFIX + i,
                  NUM_ITEMS/THREAD_COUNT));
      t.setDaemon(true);
      t.start();
      threadList.add(t);
    }
    waitForAllThread(threadList);

    Instant finishInstant = Instant.now();
    Duration duration = Duration.between(startInstant, finishInstant);

    System.out.println("SUCCESS Validate Test - elapsed Time = " + duration.getSeconds() + " seconds");
  }

  /**
   * Return the CCF which has the CloudQuorumPolicy configured for all distributed services.
   *
   * @return the CCF
   */
  private ConfigurableCacheFactory getCcf() {

    ConfigurableCacheFactory ccf =
        CacheFactory.getCacheFactoryBuilder()
            .getConfigurableCacheFactory(
                clientCacheConfigPath.toString(), getClass().getClassLoader());

    return ccf;
  }

  private void waitForAllThread(List<CacheThread> threadList) {
    for (CacheThread thread : threadList) {
      try {
        thread.join();
        ThreadConfig config = thread.config;
        System.out.println(config.operation + " " + config.prefix + " has terminated");
        if (thread.isError()) {
          String msg = "Fatal Error in thread " + config.prefix + " for operation " + config.operation + "\n" + thread.error;
          System.out.println(msg);
          throw new RuntimeException(msg);
        }
      } catch (Exception e) {
        e.printStackTrace();
        throw new RuntimeException(e);
      }
    }
  }

  /** Inner class CacheThread */
  private abstract static class CacheThread extends Thread {

    final ThreadConfig config;

    volatile String error = null;

    String getError() {
      return error;
    }

    CacheThread(ThreadConfig config) {
      this.config = config;
    }

    boolean isError() {
      return error != null;
    }

    NamedCache ensureTestCache(ConfigurableCacheFactory ccf, String cacheName) {
      NamedCache cache = null;
      final int MAX_ENSURE_RETRY = 200;
      int count = 0;
      while (cache == null) {
        try {
          Thread.sleep(1000);
          cache = ccf.ensureCache(cacheName, config.loader);
          System.out.println("Successfully Created Named Cache");
        } catch (Exception e) {
          if (++count == MAX_ENSURE_RETRY) {
            throw new RuntimeException("Unable to create Named Cache after many retries");
          }
          System.out.println("Error creating Named Cache, retrying");
        }
      }

      return cache;
    }

    public void run() {

      final int MAX_OP_RETRY = 10;
      int opRetry = 0;

      // Fill value buff
      StringBuffer valBuf = new StringBuffer(VALUE_SIZE);
      for (int i=0; i < VALUE_SIZE; i++)
        valBuf.append('a');

      try {
        System.out.println("Running " + config.operation + " thread " + config.prefix);
        NamedCache cache = ensureTestCache(config.ccf, config.cacheName);
        int count = 0;
        while (count < config.numItems)
        {
          // Load map with a batch of values
          Map<String, String> map = new HashMap<>(MAX_BATCH_SIZE);
          int remaining = config.numItems - count;
          final int batchSize = remaining > MAX_BATCH_SIZE ? MAX_BATCH_SIZE : remaining;
          for (int i =0; i <batchSize; i++) {

            // replace the leading chars in the array with the count
            String valStr = String.valueOf(count);
            valBuf.replace(0,valStr.length(),valStr);

            map.put (config.prefix + "-" + count,  valBuf.toString());
            count++;
          }
          try {
            //  System.out.println("Key = " + key);
            error = doCacheOperation(cache, map);
            if (error != null) return;
            if (delay > 0) {
              Thread.sleep(delay);
            }
          } catch (Exception e) {
            System.out.println(
                config.prefix + " Exception accessing the cache : " + e.getMessage());

            System.out.println(getStackTraceString(e));

            if (++opRetry == MAX_OP_RETRY) {
              error = "ERROR: Reached retry limit for operation " + config.operation;
              return;
            }

            System.out.println("Calling ensureCache again for " + config.prefix);
            try {
              config.ccf.releaseCache(cache);
            } catch (Exception e1) {
            } // ignore

            cache = ensureTestCache(config.ccf, config.cacheName);
            delay = 0;

            // Adjust count since the last operator failed
            count -= batchSize;
          }
        }
      } catch (Exception e) {
        error = getStackTraceString(e);
        return;
      }

      System.out.println("Finished running " + config.operation + " thread " + config.prefix);
    }

    abstract String doCacheOperation(NamedCache cache, Map<String, String>map);
  }

  /** Write the data to the cache */
  private static class WriteThread extends CacheThread {

    private WriteThread(ThreadConfig config) {
      super(config);
    }

    @Override
    String doCacheOperation(NamedCache cache, Map<String, String>map) {
   //   System.out.println("Writing Map " + mapWriteCount.incrementAndGet());
      cache.putAll(map);
      return null;
    }
  }

  /* Read and Validate the data in the Cache */
  private static class ValidateThread extends CacheThread {

    private ValidateThread(ThreadConfig config) {
      super(config);
    }

    @Override
    String doCacheOperation(NamedCache cache, Map<String, String>map) {

   //   System.out.println("Validating Map " + mapWriteCount.incrementAndGet());
      Map outMap = cache.getAll(map.keySet());
      if (!map.equals(outMap)) {
        error = "Validation Error: Cache data doesn't match";
        return error;
      }
      return null;
    }
  }

  private static class ThreadConfig {
    final ClassLoader loader;
    final String operation;
    final ConfigurableCacheFactory ccf;
    final String cacheName;
    final String prefix;
    final int numItems;

    ThreadConfig(
        ClassLoader loader,
        String operation,
        ConfigurableCacheFactory ccf,
        String cacheName,
        String prefix,
        int numItems) {

      this.loader = loader;
      this.operation = operation;
      this.ccf = ccf;
      this.cacheName = cacheName;
      this.prefix = prefix;
      this.numItems = numItems;
    }
  }
}