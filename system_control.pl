#!/usr/bin/perl
#----------------------------------------------------------------------------

=head1 pc_system_control.pl

This program is to control the systems in AWS
it reads the config/servers.json files to get the configuration 
and the group of servers to contorl to add another group you add it to the servers.json file
and the statement below in the $plan =~ line below

=cut

#----------------------------------------------------------------------------

use strict;
use warnings;

use Paws;
use Paws::Credential::Explicit;

use Data::Dumper;
use lib qw(..);

my $debug;

use JSON qw( );

my $filename = 'config/servers.json';

my ($action,$plan) = @ARGV;

unless($action =~ /^start|stop|restart$/ and $plan  =~ /^offovernight|dev$/ ){
  print "usage $0 start|stop|restart offovernight|dev\n";
  exit;
}

unless( $ENV{LOGNAME} eq "root"){
  print "you must be root to run this program";
}

my $json_text = do {
   open(my $json_fh, "<:encoding(UTF-8)", $filename)
      or die("Can't open \$filename\": $!\n");
   local $/;
   <$json_fh>
};

    my $json = JSON->new();
    my $iam;
    my $paws;
    my $data = $json->decode($json_text);
    for my $config  (@{$data->{config}}){
	if($debug){
	    print $config->{access_key}."\n";
	    print $config->{secret_key}."\n";
    	}
	$paws = Paws->new(config => {
  					credentials => Paws::Credential::Explicit->new(
   					 access_key => $config->{access_key},
    			 	 secret_key =>  $config->{secret_key}
  			)
		});
    }
    # read the servers to control
    for my  $server (@{$data->{$plan}}){
	if($debug){
	    print $server->{server}."\n";
	    print $server->{id}."\n";
	    print $server->{region}."\n";
    }
	
	$iam = $paws->service('EC2',region => $server->{region});
		if($action eq 'stop'){
			my $StopInstancesResult = $iam->StopInstances(
  				InstanceIds => [$server->{id}],
			);
		#	print Dumper  $StopInstancesResult ;
	}elsif($action eq 'start'){

		my $StartInstancesResult = $iam->StartInstances(
  			InstanceIds => [$server->{id}],
		);
	#	print Dumper  $StartInstancesResult ;
	}elsif($action eq 'restart'){
		my $RebootInstances = $iam->RebootInstances(
  			InstanceIds => [$server->{id}],
		);
		#	print Dumper $RebootInstances;
	}

}
