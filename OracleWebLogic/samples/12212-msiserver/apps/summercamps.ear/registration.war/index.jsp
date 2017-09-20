<%@ page import="java.net.InetAddress" %>
<%@ page import="javax.servlet.http.Cookie" %>
<html>
<title>Account Profile</title>
<body>
<h3>Account Profile</h3>
<%
  Object attr = session.getAttribute("counter");
  int counter = (attr != null ? ((Integer) attr) : 0);
  counter++;
  session.setAttribute("counter", counter);
  out.println("Sports camps signed up for " + counter + "<br>");
%>
<hr>
<small>
<%
  out.println("Managed Server Name " + System.getProperty("weblogic.Name") + "<br>");
  /*
  out.println("Hostname " + InetAddress.getLocalHost().getHostName() + "<br>");
  Cookie[] cookies = request.getCookies();
  String jSessionId = null;

  if (cookies != null) {
    for (int i = 0; i < cookies.length; i++) {
      if ("JSESSIONID".equals(cookies[i].getName())) {
        jSessionId = cookies[i].getValue();
      }
    }
  }
  out.println("JSESSIONID is " + jSessionId);
  */
%>
</small>
</body>
</html>
