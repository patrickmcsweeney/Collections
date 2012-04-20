$c->{plugins}->{"Screen::EPrint::Box::CollectionMembership"}->{params}->{disable} = 0;
$c->{plugins}->{"Screen::EPrint::Box::CollectionMembership"}->{appears}->{summary_top} = undef;
$c->{plugins}->{"Screen::EPrint::Box::CollectionMembership"}->{appears}->{summary_right} = 1100;
$c->{plugins}->{"Screen::EPrint::Box::CollectionMembership"}->{appears}->{summary_bottom} = undef;
$c->{plugins}->{"Screen::EPrint::Box::CollectionMembership"}->{appears}->{summary_left} = undef;

$c->{z_collection_validate_eprint} = $c->{validate_eprint};

$c->{validate_eprint} = sub
{
	my( $eprint, $session, $for_archive ) = @_;

	my @problems = ();

	if( $eprint->get_type eq 'collection' ){
		return( @problems );
	}

	@problems = $session->get_repository()->call("z_collection_validate_eprint", $eprint, $session, $for_archive);

	return( @problems );
};

$c->{z_collection_eprint_warnings} = $c->{eprint_warnings};

$c->{eprint_warnings} = sub
{
        my( $eprint, $session ) = @_;

        my @problems = ();

        if( $eprint->get_type eq 'collection' ){
                return( @problems );
        }

        @problems = $session->get_repository()->call("z_collection_eprint_warnings", $eprint, $session );

        return( @problems );
};

