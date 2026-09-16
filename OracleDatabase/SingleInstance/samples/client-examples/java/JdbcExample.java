/*
 * Query Oracle AI Database through JDBC.
 *
 * The Oracle JDBC driver (ojdbc17.jar) must be on the class path.  Set
 * ORACLE_USER and ORACLE_PASSWORD before running this example.  The optional
 * ORACLE_JDBC_URL defaults to jdbc:oracle:thin:@//localhost:1521/FREEPDB1.
 */

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public final class JdbcExample {
    private static final String DEFAULT_URL =
            "jdbc:oracle:thin:@//localhost:1521/FREEPDB1";

    private JdbcExample() {
    }

    public static void main(String[] args) throws SQLException {
        String user = requiredEnvironmentVariable("ORACLE_USER");
        String password = requiredEnvironmentVariable("ORACLE_PASSWORD");
        String url = System.getenv().getOrDefault("ORACLE_JDBC_URL", DEFAULT_URL);

        try (Connection connection = DriverManager.getConnection(url, user, password);
             PreparedStatement statement = connection.prepareStatement(
                     "SELECT banner FROM v$version");
             ResultSet resultSet = statement.executeQuery()) {
            while (resultSet.next()) {
                System.out.println(resultSet.getString(1));
            }
        }
    }

    private static String requiredEnvironmentVariable(String name) {
        String value = System.getenv(name);
        if (value == null || value.isBlank()) {
            throw new IllegalStateException("Set " + name + " before running this example.");
        }
        return value;
    }
}
