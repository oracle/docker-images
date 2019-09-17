package cohtest;

/*
 * Copyright (c) 2013-2014 Oracle and/or its affiliates. All rights reserved.
 */

import cohapp.CacheClient;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.nio.file.Path;
import java.time.Duration;
import java.time.Instant;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.After;
import org.junit.Before;
import org.junit.FixMethodOrder;
import org.junit.Test;
import org.junit.runners.MethodSorters;


/**
 * MBean unit test class. This test creates a coherence cluster so we may want to move it into a
 * functional test.
 */
@FixMethodOrder(MethodSorters.NAME_ASCENDING)
public class TestCache {

  private static final String PREFIX = "Thread-";
  private static final int VALUE_SIZE = 1024;
  private static final int NUM_ITEMS = 100 * 1000;  // Total number of items, regardless of thread count
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


  @Before
  public void beforeTest() {

  }

  @After
  public void afterTest() {}

  private static String getStackTraceString(Exception e) {
    StringWriter writer = new StringWriter();
    e.printStackTrace(new PrintWriter(writer));
    return writer.toString();
  }

  @Test
  public void a1_loadTest() {

    System.out.println("Loading cache test starting...");
    CacheClient client = new CacheClient();

    Instant startInstant = Instant.now();
    client.loadCache();
    Instant finishInstant = Instant.now();
    Duration duration = Duration.between(startInstant, finishInstant);

    System.out.println("Load Test elaspsed Time = " + duration.getSeconds() + " seconds");
  }

  @Test
  public void a2_validateTest() {

    System.out.println("Validate cache test starting...");
    CacheClient client = new CacheClient();

    Instant startInstant = Instant.now();
    client.validateCache();
    Instant finishInstant = Instant.now();
    Duration duration = Duration.between(startInstant, finishInstant);

    System.out.println("Validate Test elaspsed Time = " + duration.getSeconds() + " seconds");
  }

 }