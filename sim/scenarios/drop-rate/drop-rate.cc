#include "ns3/core-module.h"
#include "ns3/error-model.h"
#include "ns3/internet-module.h"
#include "ns3/point-to-point-module.h"
#include "../helper/quic-network-simulator-helper.h"
#include "../helper/quic-point-to-point-helper.h"
#include "drop-rate-error-model.h"

using namespace ns3;
using namespace std;

NS_LOG_COMPONENT_DEFINE("ns3 simulator");

int main(int argc, char *argv[]) {
    std::string delay, bandwidth_to_client, bandwidth_to_server, queue_type, queue_size, client_rate, server_rate;
    std::string codel_target, codel_interval;
    std::random_device rand_dev;
    std::mt19937 generator(rand_dev());  // Seed random number generator first
    Ptr<DropRateErrorModel> client_drops = CreateObject<DropRateErrorModel>();
    Ptr<DropRateErrorModel> server_drops = CreateObject<DropRateErrorModel>();
    CommandLine cmd;
    
    cmd.AddValue("delay", "delay of the p2p link", delay);
    cmd.AddValue("bandwidth_to_client", "bandwidth of the p2p link (towards client)", bandwidth_to_client);
    cmd.AddValue("bandwidth_to_server", "bandwidth of the p2p link (towards server)", bandwidth_to_server);
    cmd.AddValue("queue_type", "queue type of the p2p link (pfifo/codel)", queue_type);
    cmd.AddValue("queue_size", "queue size of the p2p link (in packets)", queue_size);
    cmd.AddValue("codel_target", "set codel queue target delay (ms)", codel_target);
    cmd.AddValue("codel_interval", "set codel queue interval (ms)", codel_interval);
    cmd.AddValue("rate_to_client", "packet drop rate (towards client)", client_rate);
    cmd.AddValue("rate_to_server", "packet drop rate (towards server)", server_rate);
    cmd.Parse (argc, argv);
    
    NS_ABORT_MSG_IF(delay.length() == 0, "Missing parameter: delay");
    NS_ABORT_MSG_IF(bandwidth_to_client.length() == 0, "Missing parameter: bandwidth_to_client");
    NS_ABORT_MSG_IF(bandwidth_to_server.length() == 0, "Missing parameter: bandwidth_to_server");
    NS_ABORT_MSG_IF(queue_size.length() == 0, "Missing parameter: queue_size");
    if (queue_type == "pfifo") {
        // do nothing
    } else if (queue_type == "codel") {
        NS_ABORT_MSG_IF(codel_target.length() == 0, "Missing parameter: codel_target");
        NS_ABORT_MSG_IF(codel_interval.length() == 0, "Missing parameter: codel_interval");
    } else {
        NS_ABORT_MSG("Unsuppoprted queue type: "+queue_type);
    }
    NS_ABORT_MSG_IF(client_rate.length() == 0, "Missing parameter: rate_to_client");
    NS_ABORT_MSG_IF(server_rate.length() == 0, "Missing parameter: rate_to_server");

    // Set client and server drop rates.
    client_drops->SetDropRate(stoi(client_rate));
    server_drops->SetDropRate(stoi(server_rate));

    QuicNetworkSimulatorHelper sim;

    // Stick in the point-to-point line between the sides.
    QuicPointToPointHelper p2p;
    p2p.SetChannelAttribute("Delay", StringValue(delay));
    if (queue_type == "pfifo") {
        p2p.SetQueueType(StringValue("ns3::PfifoFastQueueDisc"));
    } else if (queue_type == "codel") {
        p2p.SetQueueType(StringValue("ns3::CoDelQueueDisc"));
        Config::SetDefault("ns3::CoDelQueueDisc::Target", TimeValue(Time(codel_target+"ms")));
        Config::SetDefault("ns3::CoDelQueueDisc::Interval", TimeValue(Time(codel_interval+"ms")));
    }
    p2p.SetQueueSize(StringValue(queue_size + "p"));

    NetDeviceContainer devices = p2p.Install(sim.GetLeftNode(), sim.GetRightNode());

    devices.Get(0)->SetAttribute("DataRate", StringValue(bandwidth_to_server));
    devices.Get(0)->SetAttribute("ReceiveErrorModel", PointerValue(client_drops));

    devices.Get(1)->SetAttribute("DataRate", StringValue(bandwidth_to_client));
    devices.Get(1)->SetAttribute("ReceiveErrorModel", PointerValue(server_drops));
    
    sim.Run(Seconds(36000));
}
