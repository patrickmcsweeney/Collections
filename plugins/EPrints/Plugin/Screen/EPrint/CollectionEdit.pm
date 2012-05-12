package EPrints::Plugin::Screen::EPrint::CollectionEdit;

@ISA = ( 'EPrints::Plugin::Screen::EPrint::Edit' );

use strict;

sub workflow_id
{
	my ( $self ) = @_;

	if( $self->{eprint}->value("type") eq "collection" )
	{
        	return "collection";
	}
	return "default";
}
