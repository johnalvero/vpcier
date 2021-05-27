#!/usr/bin/perl

use NetAddr::IP;

my $projectcode       	= "xxx";
my $projectenv        	= "Prod";		
my $admin_ip		= "0.0.0.0/0";		# Administrators public ip. This could be the office IP
my $smtp_ip		= "0.0.0.0/0";		# SMTP IP
my $ntpserver	      	= "asia.pool.ntp.org";	# This will be resolved to IP address later in the script. Necessary NACL rules will be allowed
my $supernet 	      	= "10.0.0.0/24";	# CIDR of the VPC
my $dmz_ip_prefix     	= 28;			# IP Prefix of DMZ subnet
my $private_ip_prefix 	= 27;			# IP Prefix of Private subnet
my $db_ip_prefix 	= 27;			# IP Prefix of DB subnet



####### DO NOT EDIT BELOW THIS LINE #########

my $ip = new NetAddr::IP($supernet);
my @obj = $ip->split($dmz_ip_prefix, $dmz_ip_prefix, $private_ip_prefix, $private_ip_prefix, $db_ip_prefix, $db_ip_prefix);
#my @obj = $ip->split($dmz_ip_prefix, $dmz_ip_prefix, $private_ip_prefix, $private_ip_prefix);


$DMZ1     = $obj[0];
$DMZ2	  = $obj[1];
$PRIVATE1 = $obj[2];
$PRIVATE2 = $obj[3];
$DB1	  = $obj[4];
$DB2	  = $obj[5];

print "Supernet Info:\n\n";
print "Network    : $supernet\n";
print "Total Hosts: " . $ip->num() . "\n";
print "Range      : " . $ip->range() . "\n\n";

# Print summary
print "Subnets: \n\n";
print "$projectcode-$projectenv-DMZ1        $DMZ1\t" . $DMZ1->num() . "\n";
print "$projectcode-$projectenv-DMZ2        $DMZ2\t" . $DMZ2->num() . "\n";
print "$projectcode-$projectenv-Private1    $PRIVATE1\t" . $PRIVATE1->num() . "\n";
print "$projectcode-$projectenv-Private2    $PRIVATE2\t" . $PRIVATE2->num() . "\n";
print "$projectcode-$projectenv-DB1         $DB1\t" . $DB1->num() . "\n";
print "$projectcode-$projectenv-DB2         $DB2\t" . $DB2->num() . "\n";

# Get DNS IPs
my $dnslist=`dig $ntpserver +short \@8.8.8.8`;
my ($ntp1, $ntp2, $ntp3, $ntp4) = split('\n',$dnslist);

# Print NACL
print "\n\nNACL \n\n";
print "DMZ\n\n";

print <<"END";
Inbound
Rule #\tType\t\t\tProto\tPort Range\tSource
100\tCustom TCP Rule\t\tTCP\t1024-65535\t0.0.0.0/0 
101\tHTTP\t\t\tTCP\t80\t\t0.0.0.0/0
102\tHTTPS\t\t\tTCP\t443\t\t0.0.0.0/0
103\tCustom UDP Rule\t\tUDP\t123\t\t$ntp1/32
104\tCustom UDP Rule\t\tUDP\t123\t\t$ntp2/32
105\tCustom UDP Rule\t\tUDP\t123\t\t$ntp3/32
106\tCustom UDP Rule\t\tUDP\t123\t\t$ntp4/32
107\tCustom TCP Rule\t\tTCP\t22\t\t$admin_ip
108\tCustom TCP Rule\t\tTCP\t4444\t\t$admin_ip
109\tALL Traffic\t\tALL\tALL\t\t$DMZ1\t# DMZ1 Subnet
110\tALL Traffic\t\tALL\tALL\t\t$DMZ2\t# DMZ2 Subnet
111\tALL Traffic\t\tALL\tALL\t\t$PRIVATE1\t# Private1 Subnet
112\tALL Traffic\t\tALL\tALL\t\t$PRIVATE2\t# Private2 Subnet
END

print <<"END";
\nOutbound
Rule #\tType\t\t\tProto\tPort Range\tDestination
100\tCustom TCP Rule\t\tTCP\t1024-65535\t0.0.0.0/0
101\tHTTP\t\t\tTCP\t80\t\t0.0.0.0/0
102\tHTTPS\t\t\tTCP\t443\t\t0.0.0.0/0
103\tCustom UDP Rule\t\tUDP\t123\t\t$ntp1/32
104\tCustom UDP Rule\t\tUDP\t123\t\t$ntp2/32
105\tCustom UDP Rule\t\tUDP\t123\t\t$ntp3/32
106\tCustom UDP Rule\t\tUDP\t123\t\t$ntp4/32
107\tSMTP\t\t\tTCP\t25\t\t$smtp_ip
108\tALL Traffic\t\tALL\tALL\t\t$DMZ1\t# DMZ1 Subnet
109\tALL Traffic\t\tALL\tALL\t\t$DMZ2\t# DMZ2 Subnet
110\tALL Traffic\t\tALL\tALL\t\t$PRIVATE1\t# Private1 Subnet
111\tALL Traffic\t\tALL\tALL\t\t$PRIVATE2\t# Private2 Subnet
END


print "\n\nPrivate\n\n";
print <<"END";
Inbound
Rule #\tType\t\t\tProto\tPort Range\tSource
100\tALL Traffic\t\tALL\tALL\t\t$DMZ1\t# DMZ1 Subnet
101\tALL Traffic\t\tALL\tALL\t\t$DMZ2\t# DMZ2 Subnet
102\tALL Traffic\t\tALL\tALL\t\t$PRIVATE1\t# Private1 Subnet
103\tALL Traffic\t\tALL\tALL\t\t$PRIVATE2\t# Private2 Subnet
104\tALL Traffic\t\tALL\tALL\t\t$DB1\t# DB1 Subnet
105\tALL Traffic\t\tALL\tALL\t\t$DB2\t# DB2 Subnet
END

print <<"END";
\nOutbound
Rule #\tType\t\t\tProto\tPort Range\tDestination
100\tALL Traffic\t\tALL\tALL\t\t$DMZ1\t# DMZ1 Subnet
101\tALL Traffic\t\tALL\tALL\t\t$DMZ2\t# DMZ2 Subnet
102\tALL Traffic\t\tALL\tALL\t\t$PRIVATE1\t# Private1 Subnet
103\tALL Traffic\t\tALL\tALL\t\t$PRIVATE2\t# Private2 Subnet
104\tALL Traffic\t\tALL\tALL\t\t$DB1\t# DB1 Subnet
105\tALL Traffic\t\tALL\tALL\t\t$DB2\t# DB2 Subnet
END


print "\n\nDB\n\n";
print <<"END";
Inbound
Rule #\tType\t\t\tProto\tPort Range\tSource
100\tALL Traffic\t\tALL\tALL\t\t$PRIVATE1\t# Private1 Subnet
101\tALL Traffic\t\tALL\tALL\t\t$PRIVATE2\t# Private2 Subnet
END

print <<"END";
\nOutbound
Rule #\tType\t\t\tProto\tPort Range\tDestination
100\tALL Traffic\t\tALL\tALL\t\t$PRIVATE1\t# Private1 Subnet
101\tALL Traffic\t\tALL\tALL\t\t$PRIVATE2\t# Private2 Subnet
END

