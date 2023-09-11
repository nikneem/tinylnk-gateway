using Yarp.ReverseProxy.Configuration;
using Yarp.ReverseProxy.LoadBalancing;

namespace TinyLink.Gateway.ReverseProxy
{
    public class CustomProxyConfigProvider: IProxyConfigProvider
    {

        private CustomMemoryConfig _config;

        public IProxyConfig GetConfig() => _config;


        public CustomProxyConfigProvider()
        {
            // Load a basic configuration
            // Should be based on your application needs.
            var routeConfig = new RouteConfig
            {
                RouteId = "shortLinksRoute",
                ClusterId = "shortLinksCluster",
                Match = new RouteMatch
                {
                    Path = "/api/shortlinks/{**catch-all}"
                }
            };

            var routeConfigs = new[] { routeConfig };

            var clusterConfigs = new[]
            {
                new ClusterConfig
                {
                    ClusterId = "shortLinksCluster",
                    LoadBalancingPolicy = LoadBalancingPolicies.RoundRobin,
                    Destinations = new Dictionary<string, DestinationConfig>
                    {
                        { "default", new DestinationConfig { Address = "https://api.tinylnk.nl" } }
                    }
                }
            };

            _config = new CustomMemoryConfig(routeConfigs, clusterConfigs);
        }
    }
}