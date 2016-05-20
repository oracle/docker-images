package com.tangosol.coherence.examples ;

import com.tangosol.net.management.MBeanServerFinder;

import com.tangosol.util.Base;

import javax.management.MBeanServer;

import javax.management.remote.JMXConnectorServer;
import javax.management.remote.JMXConnectorServerFactory;
import javax.management.remote.JMXServiceURL;

import java.io.IOException;

import java.lang.management.ManagementFactory;


public class JmxmpServer
        implements MBeanServerFinder
    {
    // ----- MBeanServerFinder methods --------------------------------------

    @Override
    public JMXServiceURL findJMXServiceUrl(String s)
        {
        return s_jmxServiceURL;
        }

    @Override
    public MBeanServer findMBeanServer(String s)
        {
        return ensureServer().getMBeanServer();
        }

    // ----- helper methods -------------------------------------------------

    /**
     * Obtain the JMXMP protocol {@link JMXConnectorServer} instance, creating
     * the instance of the connector server if one does not already exist.
     *
     * @return  the JMXMP protocol {@link JMXConnectorServer} instance.
     */
    private static synchronized JMXConnectorServer ensureServer()
        {
        try
            {
            if (s_connectorServer == null)
                {
                MBeanServer server = ManagementFactory.getPlatformMBeanServer();
                int         nPort  = Integer.getInteger("coherence.jmxmp.port", 9000);

                s_jmxServiceURL   = new JMXServiceURL("jmxmp", "0.0.0.0", nPort);
                s_connectorServer = JMXConnectorServerFactory.newJMXConnectorServer(s_jmxServiceURL, null, server);

                s_connectorServer.start();
                }

            return s_connectorServer;
            }
        catch (IOException e)
            {
            throw Base.ensureRuntimeException(e);
            }
        }

    // ----- data members ---------------------------------------------------

    /**
     * The JMXServiceURL for the MBeanConnector used by the Coherence JMX framework.
     */
    private static JMXServiceURL      s_jmxServiceURL;

    /**
     * The {@link JMXConnectorServer} using the JMXMP protocol.
     */
    private static JMXConnectorServer s_connectorServer;
    }