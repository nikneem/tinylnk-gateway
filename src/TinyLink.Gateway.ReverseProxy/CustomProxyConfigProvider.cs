﻿using Yarp.ReverseProxy.Configuration;
using Yarp.ReverseProxy.LoadBalancing;

namespace TinyLink.Gateway.ReverseProxy
{
    public class CustomProxyConfigProvider : IProxyConfigProvider
    {

        private CustomMemoryConfig _config;

        public IProxyConfig GetConfig() => _config;


        public CustomProxyConfigProvider()
        {
            // Load a basic configuration
            // Should be based on your application needs.
            var shortLinksRouteConfig = new RouteConfig
            {
                RouteId = "shortLinksRoute",
                ClusterId = "shortLinksCluster",
                Match = new RouteMatch
                {
                    Path = "/api/shortlinks/{**catch-all}"
                }
            };

            var hitsRouteConfig = new RouteConfig
            {
                RouteId = "hitsRoute",
                ClusterId = "hitsCluster",
                Match = new RouteMatch
                {
                    Path = "/api/hits/{**catch-all}"
                }
            };



            var routeConfigs = new[] { shortLinksRouteConfig, hitsRouteConfig };

            var clusterConfigs = new[]
            {
                new ClusterConfig
                {
                    ClusterId = "shortLinksCluster",
                    LoadBalancingPolicy = LoadBalancingPolicies.RoundRobin,
                    Destinations = new Dictionary<string, DestinationConfig>
                    {
                        { "default", new DestinationConfig { Address = "http://tinylnk-api-ne-ca" } }
                    }
                },
                                new ClusterConfig
                {
                    ClusterId = "hitsCluster",
                    LoadBalancingPolicy = LoadBalancingPolicies.RoundRobin,
                    Destinations = new Dictionary<string, DestinationConfig>
                    {
                        { "default", new DestinationConfig { Address = "http://tinylnk-hits-ne-ca" } }
                    }
                }


            };

            _config = new CustomMemoryConfig(routeConfigs, clusterConfigs);
        }
    }
}