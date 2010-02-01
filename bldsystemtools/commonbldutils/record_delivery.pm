package record_delivery;

=head1 NAME

Record delivery

=head1 SYNOPSIS

record_delivery.pl

=head1 DESCRIPTION

This module is designed to send an email for the purpose of recording deliveries.

=head1 COPYRIGHT

Copyright (c) 2005 Symbian Ltd. All rights reserved

=cut

=over 4

=item * Template Notes

The basic rules of the template for creating a delivery record are:-
The replacement sections as per HTML::Template module rules.
%% is a seperator
Spelling and case of words is critical
General line format is:- Field name in Delivery record document%%Field value%%
No line returns will be transferred to the delivery record document
"Responsible Person" can only be a single person.
"Symbian Contact" and "Additional Email List" can be multiple people seperated by a semicolon (;)
"Consignee Name" and "Contract Identifier" are values chosen from the deliveries database
No empty fields are allowed, to simulate an empty field use a single space
All the fields shown in the example must be present.

e.g
Title%%<TMPL_VAR NAME=BuildNumber> CBR Delivery to Kshema%%
Export Controlled%%Yes%%
Reason Why Not Exported%% %%
Consignee Name%%Kshema Technologies%%
Contract Identifier%%N/A system Test 07/08/2003%%
Recipient Email%%Andrew.Beck@Symbian.com%%
Recipient Project%% %%
Additional Email List%% %%
Symbian Contact%%Monika Lewandowski; Denis Lyons%%
Responsible Person%%Monika Lewandowski%%
Source/Archive Location%%\\builds01\ODCBuilds\CBR_Archive_<TMPL_VAR NAME=BuildShortName>%%
Notification Email text%%This is a test 2 of auto delivery recording%%
Delivery Notes%%GT_Techview_Baseline Version <TMPL_VAR NAME=BuildNumber and GT_Only_Baseline Version <TMPL_VAR NAME=BuildNumber>%%

=back

=over 4

=item * Other Notes

An email will be sent back to the from_address value if the creation of the
record delivery document fails.

=cut

use 5.6.1;
use strict;
use warnings;

use Exporter;
use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS @EXPORT_FAIL);
@ISA = ('Exporter');
@EXPORT = qw(new send);
@EXPORT_FAIL = qw ();
%EXPORT_TAGS = ( ':all' =>[qw/new send/] );
$VERSION = '0.1';

use Carp;
use Net::SMTP;
use Sys::Hostname;
use HTML::Template;

sub new
{
	my ($class) = shift;
  our %args = @_;
	my $self = {};
	bless $self, $class;
	
	# Use config file if defined
	if (defined $args{'config_file'})
	{
		# populate %args from file
		do $args{'config_file'};
	}
	
	# if from address is not set then the from is the machine name
	if(!defined($args{'from_address'}))
	{
		$self->{'from_address'} = hostname;
	} else {
		$self->{'from_address'} = $args{'from_address'};
	}

	# if to address is not set then confess
	if(!defined($args{'to_address'}))
	{
		confess "ERROR: Sending email, no To: address defined";
	} else {
		$self->{'to_address'} = $args{'to_address'};
	}

	# if to smtp_server is not set then set it to the local machine
	if(!defined($args{'smtp_server'}))
	{
		$self->{'smtp_server'} = hostname;
	} else {
		$self->{'smtp_server'} = $args{'smtp_server'};
	}


  return $self;
}

sub send
{
  
  my $self = shift;

  my %args = @_;
	
	# Create the Template and allow supplied params not to exist in the template
  my $email = new HTML::Template(filename => $args{'Template'}, die_on_bad_params => 0);
	# Delete the template filename from the %args hash so a generic loop can be
	# used for other Template Variables where the key is the same as TMPL_VAR NAME
	delete $args{'Template'};
	
	#Complete Template
	foreach my $key (keys %args)
	{
		$email->param($key => $args{$key});
	}

  
  my (@message);

  push @message,"From: $self->{'from_address'}\n";
  push @message,"To: $self->{'to_address'}\n";
  push @message,"Subject: Auto Import\n";
  push @message,"\n";
  push @message,$email->output();

  my $smtp = Net::SMTP->new($self->{'smtp_server'}, Hello => hostname, Debug   => 0);
  $smtp->mail();
  $smtp->to($self->{'to_address'});

  $smtp->data(@message) or confess "ERROR: Sending email";
  $smtp->quit;
  
}

1;
