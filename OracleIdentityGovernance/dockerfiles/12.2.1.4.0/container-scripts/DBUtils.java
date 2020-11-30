// Copyright (c) 2020 Oracle and/or its affiliates.
//
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
//
// Author: OIG Development

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

public class DBUtils {

    Connection con = null;
    private static final String Separator = "/";
    private static final String DRIVER_NAME = "oracle.jdbc.driver.OracleDriver";

    static {
        try {
            Class.forName("oracle.jdbc.driver.OracleDriver").newInstance();
            System.out.println("*** Driver loaded");
        }
        catch (Exception exception) {
            System.out.println("*** Error : " + exception.toString());
            System.out.println("*** ");
            System.out.println("*** Error : ");
            exception.printStackTrace();
        }
    }

    public static void main(String[] args) {

        String DBuserName;
        DBUtils dbUtils = new DBUtils();

        // Input Validation
        if (args.length < 5 || (args.length > 5 && args[3] == "file")) {
            dbUtils.printUsage();
            System.exit(1);
        }

        // get Args to populate local Variables
        String jdbcURL = args[0];

        if ("sys".equals(args[1])) {
            DBuserName = "sys as sysdba";
        } else {
            DBuserName = args[1];
        }

        String DBPassword = args[2];

        String type = args[3];

        // Create JDBC COnnection
        dbUtils.getConnection(jdbcURL, DBuserName, DBPassword);

        try {
            // If type is a script, Get the Entire Statement
            if ("script".equals(type)) {
                String stmt = "";
                for (byte b = 4; b < args.length; b++) {
                    if (args[b].contains("*")) {
                        stmt = stmt + " *";
                    } else {
                        stmt = stmt + " " + args[b];
                    }
                }
                dbUtils.runStatement(stmt);
            }

            // Else if Type is a File,
            else if ("file".equals(type)) {
                dbUtils.runSQLFile(args[4], Separator);
            }
            else {
                dbUtils.printUsage();
            }
        }
        catch (Exception exception) {
            try {
                dbUtils.con.close();
            }
            catch (SQLException sQLException) {
                sQLException.printStackTrace();
            }
        }
        finally {
            try {
                dbUtils.con.close();
            }
            catch (SQLException sQLException) {
                sQLException.printStackTrace();
            }
        }
    }

    private void printUsage() {
        String jdbcURL = "Usage: " + getClass().getName() + "jdbcURL DBuserName DBPassword script <Script-text>";
        String DBuserName = "Usage: " + getClass().getName() + "jdbcURL DBuserName DBPassword file <fileName>";
        System.out.println(jdbcURL);
        System.out.println(DBuserName);
    }

    private Connection getConnection(String jdbcURL, String DBuserName, String DBPassword) {
        try {
            this.con = DriverManager.getConnection(jdbcURL, DBuserName, DBPassword);
            System.out.println("Conection created successfuly");
        } catch (Exception exception) {
            System.out.println(exception);
        }
        return this.con;
    }

    public boolean runStatement(String sqlStatement) {
        Statement statement = null;
        System.out.println("Running Statement --> \n" + sqlStatement);
        try {
            statement = this.con.createStatement();
        }
        catch (SQLException sQLException) {
            sQLException.printStackTrace();
            System.out.println("Not a valid SQL statement");
        }

        try {
            ResultSet resultSet = statement.executeQuery(sqlStatement);
            System.out.println("Executing the query successfully");
            while (resultSet.next())
                System.out.println(resultSet.getInt(1) + "  " + resultSet.getString(2) + "  " + resultSet.getString(3));
        }
        catch (SQLException sQLException) {
            sQLException.printStackTrace();
            System.out.println("Executing the query Throws Error");
        }

        return true;
    }

    public boolean runSQLFile(String sqlFile, String sqlFileSeparator) {
        String sqlLine = new String();
        StringBuffer sqlStatement = new StringBuffer();
        try {
            FileReader fileReader = new FileReader(new File(sqlFile));
            BufferedReader bufferedReader = new BufferedReader(fileReader);
            while ((sqlLine = bufferedReader.readLine()) != null) {
                while ((sqlLine.startsWith("--*") || sqlLine.startsWith("#")) && (sqlLine = bufferedReader.readLine()) != null);
                if (sqlLine.startsWith("/*")) {
                    while ((sqlLine = bufferedReader.readLine()) != null && !sqlLine.contains("*/"));
                    if (sqlLine != null) {
                        if (sqlLine.trim().endsWith("*/"))
                            continue;
                        if (sqlLine.contains("*/") && !sqlLine.endsWith("*/"))
                            sqlLine = sqlLine.substring(sqlLine.indexOf("*/") + 1);
                    }
                }
                if (sqlLine != null)
                    System.out.println(sqlLine);
                sqlStatement.append(" ");
                sqlStatement.append(sqlLine);
            }

            bufferedReader.close();
            String[] sqlStatementsStrings = sqlStatement.toString().split(sqlFileSeparator);
            Statement statement = this.con.createStatement();

            for (byte b = 0; b < sqlStatementsStrings.length; b++) {
                if (!sqlStatementsStrings[b].trim().equals("")) {
                    try {
                        statement.executeUpdate(sqlStatementsStrings[b]);
                    } catch (Exception exception) {
                        System.out.println("####################   Some Exception Occured  ####################### \n" + exception.toString());
                    }
                    System.out.println(">>" + sqlStatementsStrings[b]);
                }
            }
        }
        catch (Exception exception) {
            System.out.println("*** Error : " + exception.toString());
            System.out.println("*** ");
            System.out.println("*** Error running in following String: ");
            exception.printStackTrace();
            System.out.println("################################################");
            System.out.println(sqlStatement.toString());
        }
        return false;
    }
}
