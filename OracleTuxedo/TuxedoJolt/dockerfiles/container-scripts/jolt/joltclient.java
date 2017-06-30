import bea.jolt.*;

class jclient
{
	public void client(String svcname)
	{
		JoltSession session;
		JoltSessionAttributes sattr;
		JoltRemoteService  remotecall;
		JoltTransaction    trans;
		
		String userName=null;
        String userPassword=null;
        String appPassword=null;
        String userRole="myapp";
        String outstr;
		
        sattr = new JoltSessionAttributes();
        sattr.setString(sattr.APPADDRESS, "//@HOSTNAME@:1304");

        switch (sattr.checkAuthenticationLevel())
        {
                case JoltSessionAttributes.NOAUTH:
                        break;
                case JoltSessionAttributes.APPASSWORD:
                        appPassword = "appPassword";
                        break;        
                case JoltSessionAttributes.USRPASSWORD:            
                userName = "myname";             
                userPassword = "mysecret";
                appPassword = "appPassword";
                break;
        }

        sattr.setInt(sattr.IDLETIMEOUT, 300);

        session = new JoltSession(sattr, userName, userRole, userPassword, appPassword);

        remotecall = new JoltRemoteService (svcname, session);

        remotecall.setString("STRING", "hello");
        
        try{
        	remotecall.call(null);
        }catch(ApplicationException e)
        {
        	e.printStackTrace();
        	System.exit(1);
        }

        outstr = remotecall.getStringDef("STRING", null);

        if (outstr != null)
                System.out.println(svcname+": "+outstr);

        session.endSession();
	
	}
	
	public void runclient()
	{
	    String svcname1="TOUPPER";
	    
		client(svcname1);
		System.exit(0);
	}
} // end joltclient

public class joltclient
{
    public static void main (String[] args)
    {
        jclient jc=new jclient();
    	jc.runclient();
    }
}
