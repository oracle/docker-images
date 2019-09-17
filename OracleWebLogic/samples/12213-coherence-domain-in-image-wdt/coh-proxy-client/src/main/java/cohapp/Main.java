// Copyright 2019, Oracle Corporation and/or its affiliates.  All rights reserved.
// Licensed under the Universal Permissive License v 1.0 as shown at
// http://oss.oracle.com/licenses/upl.

package cohapp;

import static java.lang.System.exit;

public class Main {

  public static void main(String[] args) {

    try {
      if (args.length == 1) {
        String arg = args[0];

        CacheClient client = new CacheClient();

        if (arg.compareToIgnoreCase("load") == 0) {
          client.loadCache();
          exit(0);
        }
        else if (arg.compareToIgnoreCase("validate") == 0) {
          client.validateCache();
          exit(0);
        }
      }
      System.out.println("Param must be load or validate ");
      exit(1);

    } catch (Exception e) {
      System.out.println("Error executing cache test: " + e.getMessage());
      exit(1);
    }
  }
}
